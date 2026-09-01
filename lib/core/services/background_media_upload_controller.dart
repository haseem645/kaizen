import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

import '../constants/app_strings.dart';
import '../network/api_error.dart';
import '../utils/custom_functions.dart';
import '../utils/operation_cancellation_token.dart';
import 'background_media_upload_system_notification_bridge.dart';
import 'file_uploader.dart';

const Object _unsetBackgroundMediaUploadField = Object();

enum BackgroundMediaUploadStatus {
  idle,
  preparing,
  uploading,
  finalizing,
  completed,
  failed,
}

enum BackgroundMediaUploadCategory { training, audit }

class BackgroundMediaUploadTaskPresentation {
  const BackgroundMediaUploadTaskPresentation({
    required this.preparingTitle,
    required this.uploadingTitle,
    required this.finalizingTitle,
    required this.completedTitle,
    required this.failedTitle,
    required this.subjectLabel,
    this.activeDetail = AppStrings.backgroundUploadContinues,
    this.preparingDetail,
    this.finalizingDetail,
    this.completedDetail,
  });

  final String preparingTitle;
  final String uploadingTitle;
  final String finalizingTitle;
  final String completedTitle;
  final String failedTitle;
  final String subjectLabel;
  final String activeDetail;
  final String? preparingDetail;
  final String? finalizingDetail;
  final String? completedDetail;
}

class BackgroundMediaUploadPreparedFile {
  const BackgroundMediaUploadPreparedFile({
    required this.uploadFile,
    required this.sourceFileName,
    required this.uploadFileName,
    required this.contentType,
    required this.usedCompressedFile,
    required this.originalSizeBytes,
    required this.uploadSizeBytes,
  });

  final File uploadFile;
  final String sourceFileName;
  final String uploadFileName;
  final String contentType;
  final bool usedCompressedFile;
  final int originalSizeBytes;
  final int uploadSizeBytes;

  static Future<BackgroundMediaUploadPreparedFile> fromSourceFile(
    File sourceFile, {
    required String fallbackFileName,
    required String fallbackContentType,
  }) async {
    final sourceFileName = CustomFunctions.fileNameFromPath(
      sourceFile.path,
      fallback: fallbackFileName,
    );
    final originalSizeBytes = await sourceFile.length();
    return BackgroundMediaUploadPreparedFile(
      uploadFile: sourceFile,
      sourceFileName: sourceFileName,
      uploadFileName: sourceFileName,
      contentType: CustomFunctions.contentTypeFromPath(
        sourceFile.path,
        fallback: fallbackContentType,
      ),
      usedCompressedFile: false,
      originalSizeBytes: originalSizeBytes,
      uploadSizeBytes: originalSizeBytes,
    );
  }
}

class BackgroundMediaUploadTarget {
  const BackgroundMediaUploadTarget({required this.uploadUrl, this.fileUrl});

  final String uploadUrl;
  final String? fileUrl;
}

class BackgroundMediaUploadResult {
  const BackgroundMediaUploadResult({this.payload});

  final Object? payload;
}

class BackgroundMediaUploadFinalizationContext {
  const BackgroundMediaUploadFinalizationContext({
    required this.preparedFile,
    required this.uploadTarget,
  });

  final BackgroundMediaUploadPreparedFile preparedFile;
  final BackgroundMediaUploadTarget uploadTarget;
}

class BackgroundMediaUploadRequest {
  const BackgroundMediaUploadRequest({
    required this.category,
    required this.presentation,
    required this.sourceFile,
    required this.fallbackErrorMessage,
    required this.prepareUpload,
    required this.createUploadTarget,
    required this.finalizeUpload,
    this.metadata = const <String, String>{},
    this.activeTaskKey,
    this.alreadyInProgressErrorMessage,
    this.afterSuccess,
    this.errorMessageResolver,
  });

  final BackgroundMediaUploadCategory category;
  final BackgroundMediaUploadTaskPresentation presentation;
  final File sourceFile;
  final String fallbackErrorMessage;
  final Map<String, String> metadata;
  final String? activeTaskKey;
  final String? alreadyInProgressErrorMessage;
  final Future<BackgroundMediaUploadPreparedFile> Function(File sourceFile)
  prepareUpload;
  final Future<BackgroundMediaUploadTarget> Function(
    BackgroundMediaUploadPreparedFile preparedFile,
  )
  createUploadTarget;
  final Future<BackgroundMediaUploadResult> Function(
    BackgroundMediaUploadFinalizationContext context,
  )
  finalizeUpload;
  final Future<void> Function(BackgroundMediaUploadResult result)? afterSuccess;
  final String Function(Object error, String fallbackMessage)?
  errorMessageResolver;
}

class BackgroundMediaUploadTask {
  const BackgroundMediaUploadTask({
    required this.taskId,
    required this.category,
    required this.status,
    required this.presentation,
    required this.sourceFilePath,
    required this.sourceFileName,
    required this.uploadFilePath,
    required this.uploadFileName,
    required this.originalSizeBytes,
    required this.uploadSizeBytes,
    required this.uploadProgress,
    required this.usedCompressedFile,
    required this.metadata,
    this.activeTaskKey,
    this.errorMessage,
    this.resultPayload,
    this.terminalEventSequence = 0,
  });

  final int taskId;
  final BackgroundMediaUploadCategory category;
  final BackgroundMediaUploadStatus status;
  final BackgroundMediaUploadTaskPresentation presentation;
  final String sourceFilePath;
  final String sourceFileName;
  final String uploadFilePath;
  final String uploadFileName;
  final int originalSizeBytes;
  final int uploadSizeBytes;
  final double uploadProgress;
  final bool usedCompressedFile;
  final String? activeTaskKey;
  final Map<String, String> metadata;
  final String? errorMessage;
  final Object? resultPayload;
  final int terminalEventSequence;

  bool get isActive =>
      status == BackgroundMediaUploadStatus.preparing ||
      status == BackgroundMediaUploadStatus.uploading ||
      status == BackgroundMediaUploadStatus.finalizing;

  bool get isUploading => status == BackgroundMediaUploadStatus.uploading;
  bool get isCompleted => status == BackgroundMediaUploadStatus.completed;
  bool get isFailed => status == BackgroundMediaUploadStatus.failed;
  bool get canCancel =>
      status == BackgroundMediaUploadStatus.preparing ||
      status == BackgroundMediaUploadStatus.uploading;
  bool get canDismiss => isCompleted || isFailed;

  double? get progressValue {
    if (status == BackgroundMediaUploadStatus.uploading) {
      return uploadProgress.clamp(0, 1).toDouble();
    }

    if (status == BackgroundMediaUploadStatus.completed ||
        status == BackgroundMediaUploadStatus.finalizing) {
      return 1;
    }

    return null;
  }

  String get localFilePath =>
      uploadFilePath.trim().isNotEmpty ? uploadFilePath : sourceFilePath;

  String get sizeSummaryLabel {
    if (originalSizeBytes <= 0) {
      return '';
    }

    final resolvedUploadSizeBytes = uploadSizeBytes > 0
        ? uploadSizeBytes
        : originalSizeBytes;
    final originalSize = CustomFunctions.formatFileSize(originalSizeBytes);
    final uploadSize = CustomFunctions.formatFileSize(resolvedUploadSizeBytes);
    if (resolvedUploadSizeBytes == originalSizeBytes) {
      return originalSize;
    }

    return '$originalSize -> $uploadSize';
  }

  String get bannerTitle {
    switch (status) {
      case BackgroundMediaUploadStatus.preparing:
        return presentation.preparingTitle;
      case BackgroundMediaUploadStatus.uploading:
        return presentation.uploadingTitle;
      case BackgroundMediaUploadStatus.finalizing:
        return presentation.finalizingTitle;
      case BackgroundMediaUploadStatus.completed:
        return presentation.completedTitle;
      case BackgroundMediaUploadStatus.failed:
        return presentation.failedTitle;
      case BackgroundMediaUploadStatus.idle:
        return '';
    }
  }

  String get bannerMessage {
    if (isFailed) {
      final resolvedError = errorMessage?.trim();
      if (resolvedError != null && resolvedError.isNotEmpty) {
        return resolvedError;
      }
    }

    final sizeSummary = sizeSummaryLabel;
    if (sizeSummary.isNotEmpty) {
      return sizeSummary;
    }

    return presentation.subjectLabel;
  }

  String? get bannerDetail {
    if (status == BackgroundMediaUploadStatus.uploading) {
      final progressPercent = (uploadProgress * 100).clamp(0, 100).round();
      return AppStrings.backgroundUploadProgressLabel(progressPercent);
    }

    if (status == BackgroundMediaUploadStatus.preparing) {
      final detail =
          presentation.preparingDetail?.trim() ?? presentation.activeDetail;
      return detail.isEmpty ? null : detail;
    }

    if (status == BackgroundMediaUploadStatus.finalizing) {
      final detail =
          presentation.finalizingDetail?.trim() ?? presentation.activeDetail;
      return detail.isEmpty ? null : detail;
    }

    if (status == BackgroundMediaUploadStatus.completed) {
      final detail = presentation.completedDetail?.trim();
      return detail == null || detail.isEmpty ? null : detail;
    }

    if (isActive) {
      return presentation.activeDetail;
    }

    return null;
  }

  T? resultPayloadAs<T>() {
    final payload = resultPayload;
    return payload is T ? payload : null;
  }

  BackgroundMediaUploadTask copyWith({
    BackgroundMediaUploadStatus? status,
    BackgroundMediaUploadTaskPresentation? presentation,
    String? sourceFilePath,
    String? sourceFileName,
    String? uploadFilePath,
    String? uploadFileName,
    int? originalSizeBytes,
    int? uploadSizeBytes,
    double? uploadProgress,
    bool? usedCompressedFile,
    Map<String, String>? metadata,
    Object? errorMessage = _unsetBackgroundMediaUploadField,
    Object? resultPayload = _unsetBackgroundMediaUploadField,
    int? terminalEventSequence,
  }) {
    return BackgroundMediaUploadTask(
      taskId: taskId,
      category: category,
      status: status ?? this.status,
      presentation: presentation ?? this.presentation,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      uploadFilePath: uploadFilePath ?? this.uploadFilePath,
      uploadFileName: uploadFileName ?? this.uploadFileName,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      uploadSizeBytes: uploadSizeBytes ?? this.uploadSizeBytes,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      usedCompressedFile: usedCompressedFile ?? this.usedCompressedFile,
      metadata: Map<String, String>.unmodifiable(metadata ?? this.metadata),
      activeTaskKey: activeTaskKey,
      errorMessage: identical(errorMessage, _unsetBackgroundMediaUploadField)
          ? this.errorMessage
          : errorMessage as String?,
      resultPayload: identical(resultPayload, _unsetBackgroundMediaUploadField)
          ? this.resultPayload
          : resultPayload,
      terminalEventSequence:
          terminalEventSequence ?? this.terminalEventSequence,
    );
  }
}

class BackgroundMediaUploadController extends ChangeNotifier {
  BackgroundMediaUploadController._({FileUploader? fileUploader})
    : _fileUploader = fileUploader ?? const FileUploader();

  static final BackgroundMediaUploadController instance =
      BackgroundMediaUploadController._();

  final FileUploader _fileUploader;
  final Map<int, BackgroundMediaUploadTask> _tasksById =
      <int, BackgroundMediaUploadTask>{};
  final Map<int, OperationCancellationToken> _cancellationTokensByTaskId =
      <int, OperationCancellationToken>{};

  int _nextTaskId = 0;
  int _terminalEventSequence = 0;
  bool _hasPendingNotification = false;
  bool _isConsumingNotificationCancellationRequests = false;
  String? _startErrorMessage;
  String _lastSystemNotificationSignature = '';
  Timer? _notificationCancellationPollingTimer;

  String? get startErrorMessage => _startErrorMessage;
  int get latestTerminalEventSequence => _terminalEventSequence;
  bool get isActive => _tasksById.values.any((task) => task.isActive);
  bool get shouldShowBanner => _tasksById.isNotEmpty;

  List<BackgroundMediaUploadTask> get visibleTasks {
    final tasks = _tasksById.values.toList(growable: false);
    tasks.sort(_compareVisibleTasks);
    return tasks;
  }

  List<BackgroundMediaUploadTask> terminalTasksSince(int eventSequence) {
    final tasks = _tasksById.values
        .where((task) => task.terminalEventSequence > eventSequence)
        .toList(growable: false);
    tasks.sort(
      (left, right) =>
          left.terminalEventSequence.compareTo(right.terminalEventSequence),
    );
    return tasks;
  }

  bool isTaskActiveForKey(String activeTaskKey) {
    final resolvedKey = activeTaskKey.trim();
    if (resolvedKey.isEmpty) {
      return false;
    }

    return _tasksById.values.any(
      (task) => task.isActive && task.activeTaskKey == resolvedKey,
    );
  }

  Future<bool> startUpload(BackgroundMediaUploadRequest request) async {
    final sourceFile = request.sourceFile;
    if (!await sourceFile.exists()) {
      _startErrorMessage = request.fallbackErrorMessage;
      return false;
    }

    final activeTaskKey = request.activeTaskKey?.trim();
    if (activeTaskKey != null &&
        activeTaskKey.isNotEmpty &&
        isTaskActiveForKey(activeTaskKey)) {
      _startErrorMessage =
          request.alreadyInProgressErrorMessage ?? request.fallbackErrorMessage;
      return false;
    }

    final sourceFileName = CustomFunctions.fileNameFromPath(sourceFile.path);
    final originalSizeBytes = await sourceFile.length();
    final taskId = _nextTaskId + 1;
    final cancellationToken = OperationCancellationToken();

    _startErrorMessage = null;
    _nextTaskId = taskId;
    _tasksById[taskId] = BackgroundMediaUploadTask(
      taskId: taskId,
      category: request.category,
      status: BackgroundMediaUploadStatus.preparing,
      presentation: request.presentation,
      sourceFilePath: sourceFile.path,
      sourceFileName: sourceFileName,
      uploadFilePath: sourceFile.path,
      uploadFileName: sourceFileName,
      originalSizeBytes: originalSizeBytes,
      uploadSizeBytes: originalSizeBytes,
      uploadProgress: 0,
      usedCompressedFile: false,
      metadata: Map<String, String>.unmodifiable(
        Map<String, String>.from(request.metadata),
      ),
      activeTaskKey: activeTaskKey,
    );
    _cancellationTokensByTaskId[taskId] = cancellationToken;
    _notifyListenersSafely();

    unawaited(
      _performUpload(
        taskId: taskId,
        request: request,
        cancellationToken: cancellationToken,
      ),
    );

    return true;
  }

  bool cancelUpload(int taskId) {
    final task = _tasksById[taskId];
    if (task == null || !task.canCancel) {
      return false;
    }

    _cancellationTokensByTaskId.remove(taskId)?.cancel();
    _tasksById.remove(taskId);
    _notifyListenersSafely();
    return true;
  }

  void dismissTask(int taskId) {
    final task = _tasksById[taskId];
    if (task == null || !task.canDismiss) {
      return;
    }

    _tasksById.remove(taskId);
    _notifyListenersSafely();
  }

  Future<void> _performUpload({
    required int taskId,
    required BackgroundMediaUploadRequest request,
    required OperationCancellationToken cancellationToken,
  }) async {
    try {
      final preparedFile = await request.prepareUpload(request.sourceFile);
      if (!_hasTask(taskId)) {
        return;
      }

      _updateTask(
        taskId,
        (task) => task.copyWith(
          status: BackgroundMediaUploadStatus.uploading,
          uploadFilePath: preparedFile.uploadFile.path,
          uploadFileName: preparedFile.uploadFileName,
          uploadSizeBytes: preparedFile.uploadSizeBytes,
          usedCompressedFile: preparedFile.usedCompressedFile,
          uploadProgress: 0,
        ),
      );
      _notifyListenersSafely();

      final uploadTarget = await request.createUploadTarget(preparedFile);
      if (!_hasTask(taskId)) {
        return;
      }

      final normalizedUploadUrl = uploadTarget.uploadUrl.trim();
      await _fileUploader.uploadBinaryFileFromFile(
        uploadUrl: normalizedUploadUrl,
        file: preparedFile.uploadFile,
        contentType: preparedFile.contentType,
        cancellationToken: cancellationToken,
        onProgress: (progress) {
          if (!_hasTask(taskId)) {
            return;
          }

          _updateTask(
            taskId,
            (task) =>
                task.copyWith(uploadProgress: progress.clamp(0, 1).toDouble()),
          );
          _notifyListenersSafely();
        },
      );
      if (!_hasTask(taskId)) {
        return;
      }

      _updateTask(
        taskId,
        (task) => task.copyWith(
          status: BackgroundMediaUploadStatus.finalizing,
          uploadProgress: 1,
        ),
      );
      _notifyListenersSafely();

      final result = await request.finalizeUpload(
        BackgroundMediaUploadFinalizationContext(
          preparedFile: preparedFile,
          uploadTarget: uploadTarget,
        ),
      );
      if (!_hasTask(taskId)) {
        return;
      }

      _terminalEventSequence += 1;
      _cancellationTokensByTaskId.remove(taskId);
      _updateTask(
        taskId,
        (task) => task.copyWith(
          status: BackgroundMediaUploadStatus.completed,
          uploadProgress: 1,
          resultPayload: result.payload,
          terminalEventSequence: _terminalEventSequence,
        ),
      );
      _notifyListenersSafely();

      final afterSuccess = request.afterSuccess;
      if (afterSuccess != null) {
        unawaited(afterSuccess(result));
      }
    } on OperationCancelledException {
      _cancellationTokensByTaskId.remove(taskId);
      if (_hasTask(taskId)) {
        _tasksById.remove(taskId);
        _notifyListenersSafely();
      }
    } catch (error) {
      if (!_hasTask(taskId)) {
        return;
      }

      _terminalEventSequence += 1;
      _cancellationTokensByTaskId.remove(taskId);
      _updateTask(
        taskId,
        (task) => task.copyWith(
          status: BackgroundMediaUploadStatus.failed,
          errorMessage:
              request.errorMessageResolver?.call(
                error,
                request.fallbackErrorMessage,
              ) ??
              _resolveUploadErrorMessage(error, request.fallbackErrorMessage),
          terminalEventSequence: _terminalEventSequence,
        ),
      );
      _notifyListenersSafely();
    }
  }

  bool _hasTask(int taskId) => _tasksById.containsKey(taskId);

  void _updateTask(
    int taskId,
    BackgroundMediaUploadTask Function(BackgroundMediaUploadTask task) update,
  ) {
    final currentTask = _tasksById[taskId];
    if (currentTask == null) {
      return;
    }

    _tasksById[taskId] = update(currentTask);
  }

  int _compareVisibleTasks(
    BackgroundMediaUploadTask left,
    BackgroundMediaUploadTask right,
  ) {
    if (left.isActive != right.isActive) {
      return left.isActive ? -1 : 1;
    }

    final leftOrder = left.isActive ? left.taskId : left.terminalEventSequence;
    final rightOrder = right.isActive
        ? right.taskId
        : right.terminalEventSequence;
    return rightOrder.compareTo(leftOrder);
  }

  String _resolveUploadErrorMessage(Object error, String fallbackMessage) {
    if (error is ApiError) {
      return error.toString();
    }

    if (error is OperationCancelledException) {
      return fallbackMessage;
    }

    if (error is SocketException ||
        error is HttpException ||
        error is http.ClientException) {
      return fallbackMessage;
    }

    final resolved = error.toString().trim();
    if (resolved.isEmpty) {
      return fallbackMessage;
    }

    return resolved;
  }

  void _notifyListenersSafely() {
    _syncSystemNotifications();
    _syncNotificationCancellationPolling();
    if (_hasPendingNotification) {
      return;
    }

    _hasPendingNotification = true;
    void dispatchNotification() {
      _hasPendingNotification = false;
      notifyListeners();
    }

    final scheduler = SchedulerBinding.instance;
    final phase = scheduler.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      scheduleMicrotask(dispatchNotification);
      return;
    }

    scheduler.addPostFrameCallback((_) {
      dispatchNotification();
    });
  }

  void _syncSystemNotifications() {
    final notificationPayloads = visibleTasks
        .map(_buildSystemNotificationPayload)
        .toList(growable: false);
    final signature = notificationPayloads
        .map(
          (payload) => [
            payload['taskId'],
            payload['status'],
            payload['title'],
            payload['message'],
            payload['progressPercent'],
            payload['canCancel'],
            payload['isOngoing'],
          ].join('|'),
        )
        .join('||');
    if (signature == _lastSystemNotificationSignature) {
      return;
    }

    _lastSystemNotificationSignature = signature;
    BackgroundMediaUploadSystemNotificationBridge.instance.queueSync(
      notificationPayloads,
    );
  }

  Map<String, Object?> _buildSystemNotificationPayload(
    BackgroundMediaUploadTask task,
  ) {
    final progressPercent = task.progressValue == null
        ? null
        : (task.progressValue! * 100).clamp(0, 100).round();
    final notificationProgressPercent = progressPercent == null
        ? null
        : Platform.isIOS
        ? ((progressPercent / 10).round() * 10).clamp(0, 100)
        : progressPercent;
    final subjectLabel = task.presentation.subjectLabel.trim().isNotEmpty
        ? task.presentation.subjectLabel.trim()
        : task.sourceFileName;
    final bannerMessage = task.bannerMessage.trim();
    final detailLabel = task.bannerDetail?.trim();
    final messageParts = <String>[subjectLabel];
    if (task.isFailed) {
      if (bannerMessage.isNotEmpty && bannerMessage != subjectLabel) {
        messageParts.add(bannerMessage);
      }
    } else if (detailLabel != null && detailLabel.isNotEmpty) {
      messageParts.add(detailLabel);
    } else if (bannerMessage.isNotEmpty && bannerMessage != subjectLabel) {
      messageParts.add(bannerMessage);
    }

    return <String, Object?>{
      'taskId': task.taskId,
      'status': task.status.name,
      'title': task.bannerTitle,
      'message': messageParts.join(' • '),
      'progressPercent': notificationProgressPercent,
      'canCancel': task.canCancel,
      'isOngoing': task.isActive,
    };
  }

  void _syncNotificationCancellationPolling() {
    final shouldPoll = _tasksById.values.any((task) => task.canCancel);
    if (!shouldPoll) {
      _notificationCancellationPollingTimer?.cancel();
      _notificationCancellationPollingTimer = null;
      return;
    }

    _notificationCancellationPollingTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        unawaited(_consumePendingNotificationCancellationRequests());
      },
    );
  }

  Future<void> _consumePendingNotificationCancellationRequests() async {
    if (_isConsumingNotificationCancellationRequests) {
      return;
    }

    _isConsumingNotificationCancellationRequests = true;
    try {
      final pendingTaskIds = await BackgroundMediaUploadSystemNotificationBridge
          .instance
          .consumePendingCancelledTaskIds();
      if (pendingTaskIds.isEmpty) {
        return;
      }

      for (final taskId in pendingTaskIds) {
        cancelUpload(taskId);
      }
    } finally {
      _isConsumingNotificationCancellationRequests = false;
    }
  }
}
