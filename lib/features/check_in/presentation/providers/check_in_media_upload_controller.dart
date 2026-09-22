import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/background_media_upload_controller.dart';
import '../../../../core/services/file_uploader.dart';
import '../../../check_in/data/datasources/audit_remote_data_source.dart';
import '../../../check_in/data/repositories/audit_repository_impl.dart';
import '../../../check_in/domain/repositories/audit_repository.dart';

enum CheckInMediaUploadFlow { descriptionComment, mediaAttachment }

class CheckInMediaUploadResult {
  const CheckInMediaUploadResult({
    required this.mediaUrl,
    required this.mediaType,
  });

  final String mediaUrl;
  final String mediaType;
}

class CheckInMediaUploadTask {
  const CheckInMediaUploadTask._(this._task);

  final BackgroundMediaUploadTask _task;

  static const String _descriptionIdKey = 'descriptionId';
  static const String _auditMediaIdKey = 'auditMediaId';
  static const String _flowKey = 'flow';

  int get taskId => _task.taskId;
  String get descriptionId => _task.metadata[_descriptionIdKey] ?? '';
  String get auditMediaId => _task.metadata[_auditMediaIdKey] ?? '';
  String? get errorMessage => _task.errorMessage;
  bool get isCompleted => _task.isCompleted;
  bool get isFailed => _task.isFailed;
  bool get isActive => _task.isActive;
  int get terminalEventSequence => _task.terminalEventSequence;
  CheckInMediaUploadResult? get resultPayload =>
      _task.resultPayloadAs<CheckInMediaUploadResult>();

  CheckInMediaUploadFlow get flow {
    final flow = _task.metadata[_flowKey];
    return flow == 'mediaAttachment'
        ? CheckInMediaUploadFlow.mediaAttachment
        : CheckInMediaUploadFlow.descriptionComment;
  }

  static CheckInMediaUploadTask fromBackgroundTask(
    BackgroundMediaUploadTask task,
  ) {
    return CheckInMediaUploadTask._(task);
  }
}

class CheckInMediaUploadController extends ChangeNotifier {
  CheckInMediaUploadController._({
    AuditRepository? auditRepository,
    FileUploader? fileUploader,
    BackgroundMediaUploadController? backgroundUploadController,
  }) : _auditRepository =
           auditRepository ?? AuditRepositoryImpl(AuditRemoteDataSource()),
       _fileUploader = fileUploader ?? const FileUploader(),
       _backgroundUploadController =
           backgroundUploadController ??
           BackgroundMediaUploadController.instance {
    _backgroundUploadController.addListener(_handleBackgroundUploadsChanged);
  }

  static final CheckInMediaUploadController instance =
      CheckInMediaUploadController._();

  static const String _descriptionIdKey = 'descriptionId';
  static const String _auditMediaIdKey = 'auditMediaId';
  static const String _flowKey = 'flow';

  final AuditRepository _auditRepository;
  final FileUploader _fileUploader;
  final BackgroundMediaUploadController _backgroundUploadController;

  String? get startErrorMessage =>
      _backgroundUploadController.startErrorMessage;
  int get latestTerminalEventSequence =>
      _backgroundUploadController.latestTerminalEventSequence;

  List<CheckInMediaUploadTask> terminalTasksSince(int eventSequence) {
    return _backgroundUploadController
        .terminalTasksSince(eventSequence)
        .where((task) => task.category == BackgroundMediaUploadCategory.audit)
        .map(CheckInMediaUploadTask.fromBackgroundTask)
        .toList(growable: false);
  }

  bool isUploadActiveForAuditMedia(String auditMediaId) {
    final resolvedAuditMediaId = auditMediaId.trim();
    if (resolvedAuditMediaId.isEmpty) {
      return false;
    }

    return _backgroundUploadController.isTaskActiveForKey(
      _auditMediaActiveKey(resolvedAuditMediaId),
    );
  }

  Future<bool> startUploadForDescriptionMediaComment({
    required String descriptionId,
    required String comment,
    required File sourceFile,
    required String mediaType,
  }) {
    final resolvedDescriptionId = descriptionId.trim();
    final resolvedComment = comment.trim();
    final resolvedMediaType = mediaType.trim();
    if (resolvedDescriptionId.isEmpty || resolvedMediaType.isEmpty) {
      return Future<bool>.value(false);
    }

    final subjectLabel = _resolvedSubjectLabel(sourceFile);
    return _backgroundUploadController.startUpload(
      BackgroundMediaUploadRequest(
        category: BackgroundMediaUploadCategory.audit,
        sourceFile: sourceFile,
        fallbackErrorMessage: AppStrings.auditMediaUploadFailed,
        metadata: <String, String>{
          _descriptionIdKey: resolvedDescriptionId,
          _flowKey: 'descriptionComment',
        },
        presentation: BackgroundMediaUploadTaskPresentation(
          preparingTitle: AppStrings.auditCommentMediaPreparing,
          uploadingTitle: AppStrings.auditCommentMediaUploading,
          finalizingTitle: AppStrings.auditCommentMediaFinalizing,
          completedTitle: AppStrings.auditCommentMediaCompleted,
          failedTitle: AppStrings.auditCommentMediaFailed,
          subjectLabel: subjectLabel,
          activeDetail: AppStrings.backgroundUploadContinues,
        ),
        prepareUpload: (file) =>
            BackgroundMediaUploadPreparedFile.fromSourceFile(
              file,
              fallbackFileName: 'audit_media.mp4',
              fallbackContentType: 'video/mp4',
            ),
        createUploadTarget: (preparedFile) async {
          final uploadUrl = await _auditRepository
              .generateAuditDescriptionMediaUploadUrl(
                fileName: preparedFile.uploadFileName,
              );
          return BackgroundMediaUploadTarget(uploadUrl: uploadUrl.trim());
        },
        finalizeUpload: (context) async {
          final mediaUrl =
              context.uploadTarget.fileUrl?.trim() ??
              _fileUploader.publicUrlFromUploadUrl(
                context.uploadTarget.uploadUrl.trim(),
              );
          await _auditRepository.createAuditDescriptionMedia(
            descriptionId: resolvedDescriptionId,
            comment: resolvedComment,
            mediaUrl: mediaUrl,
            mediaType: resolvedMediaType,
          );
          return BackgroundMediaUploadResult(
            payload: CheckInMediaUploadResult(
              mediaUrl: mediaUrl,
              mediaType: resolvedMediaType,
            ),
          );
        },
      ),
    );
  }

  Future<bool> startUploadForAuditMediaAttachment({
    required String auditMediaId,
    required File sourceFile,
    required String mediaType,
  }) {
    final resolvedAuditMediaId = auditMediaId.trim();
    final resolvedMediaType = mediaType.trim();
    if (resolvedAuditMediaId.isEmpty || resolvedMediaType.isEmpty) {
      return Future<bool>.value(false);
    }

    final subjectLabel = _resolvedSubjectLabel(sourceFile);
    return _backgroundUploadController.startUpload(
      BackgroundMediaUploadRequest(
        category: BackgroundMediaUploadCategory.audit,
        sourceFile: sourceFile,
        fallbackErrorMessage: AppStrings.auditMediaUploadFailed,
        activeTaskKey: _auditMediaActiveKey(resolvedAuditMediaId),
        alreadyInProgressErrorMessage:
            AppStrings.auditMediaUploadAlreadyInProgress,
        metadata: <String, String>{
          _auditMediaIdKey: resolvedAuditMediaId,
          _flowKey: 'mediaAttachment',
        },
        presentation: BackgroundMediaUploadTaskPresentation(
          preparingTitle: AppStrings.auditAttachmentPreparing,
          uploadingTitle: AppStrings.auditAttachmentUploading,
          finalizingTitle: AppStrings.auditAttachmentFinalizing,
          completedTitle: AppStrings.auditAttachmentCompleted,
          failedTitle: AppStrings.auditAttachmentFailed,
          subjectLabel: subjectLabel,
          activeDetail: AppStrings.backgroundUploadContinues,
        ),
        prepareUpload: (file) =>
            BackgroundMediaUploadPreparedFile.fromSourceFile(
              file,
              fallbackFileName: 'audit_media.mp4',
              fallbackContentType: 'video/mp4',
            ),
        createUploadTarget: (preparedFile) async {
          final uploadUrl = await _auditRepository
              .generateAuditDescriptionMediaUploadUrl(
                fileName: preparedFile.uploadFileName,
              );
          return BackgroundMediaUploadTarget(uploadUrl: uploadUrl.trim());
        },
        finalizeUpload: (context) async {
          final mediaUrl =
              context.uploadTarget.fileUrl?.trim() ??
              _fileUploader.publicUrlFromUploadUrl(
                context.uploadTarget.uploadUrl.trim(),
              );
          await _auditRepository.updateAuditMedia(
            auditMediaId: resolvedAuditMediaId,
            mediaUrl: mediaUrl,
            mediaType: resolvedMediaType,
          );
          return BackgroundMediaUploadResult(
            payload: CheckInMediaUploadResult(
              mediaUrl: mediaUrl,
              mediaType: resolvedMediaType,
            ),
          );
        },
      ),
    );
  }

  void _handleBackgroundUploadsChanged() {
    notifyListeners();
  }

  String _auditMediaActiveKey(String auditMediaId) {
    return 'audit-media:$auditMediaId';
  }

  String _resolvedSubjectLabel(File sourceFile) {
    final fileName = sourceFile.uri.pathSegments.isEmpty
        ? ''
        : sourceFile.uri.pathSegments.last.trim();
    return fileName.isEmpty ? AppStrings.auditUploadVideo : fileName;
  }
}
