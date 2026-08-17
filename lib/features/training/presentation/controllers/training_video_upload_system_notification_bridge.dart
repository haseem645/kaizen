import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/constants/app_strings.dart';

class TrainingVideoUploadSystemNotificationBridge with WidgetsBindingObserver {
  TrainingVideoUploadSystemNotificationBridge._();

  static final TrainingVideoUploadSystemNotificationBridge instance =
      TrainingVideoUploadSystemNotificationBridge._();

  static const MethodChannel _channel = MethodChannel(
    'kaizenteams/training_video_upload_notifications',
  );

  static const Duration _syncDebounceDuration = Duration(milliseconds: 60);

  Timer? _syncDebounceTimer;
  List<Map<String, Object?>> _pendingTaskPayloads =
      const <Map<String, Object?>>[];
  bool _didRequestPermission = false;
  bool _didRegisterLifecycleObserver = false;
  bool _isAppInForeground = true;

  void queueSync(List<Map<String, Object?>> taskPayloads) {
    _ensureLifecycleObserverRegistered();
    _pendingTaskPayloads = List<Map<String, Object?>>.unmodifiable(
      taskPayloads.map((task) => Map<String, Object?>.from(task)),
    );

    if (!_isAppInForeground) {
      _syncDebounceTimer?.cancel();
      unawaited(_flushSync());
      return;
    }

    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounceDuration, _flushSync);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasInForeground = _isAppInForeground;
    _isAppInForeground = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };

    if (wasInForeground &&
        !_isAppInForeground &&
        _pendingTaskPayloads.isNotEmpty) {
      _syncDebounceTimer?.cancel();
      unawaited(_flushSync());
    }
  }

  Future<List<int>> consumePendingCancelledTaskIds() async {
    try {
      final result = await _channel.invokeListMethod<Object?>(
        'consumePendingCancelledTrainingUploadTaskIds',
      );
      if (result == null || result.isEmpty) {
        return const <int>[];
      }

      return result
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(growable: false);
    } catch (error) {
      debugPrint(
        'Unable to consume training upload notification cancellations: $error',
      );
      return const <int>[];
    }
  }

  Future<void> _flushSync() async {
    _syncDebounceTimer = null;
    final taskPayloads = _pendingTaskPayloads;

    if (taskPayloads.isNotEmpty && !_didRequestPermission) {
      _didRequestPermission = true;
      try {
        await _channel.invokeMethod<void>(
          'requestTrainingUploadNotificationPermission',
        );
      } catch (error) {
        debugPrint(
          'Unable to request training upload notification permission: $error',
        );
      }
    }

    try {
      await _channel.invokeMethod<void>('syncTrainingUploadNotifications', {
        'channelName': AppStrings.trainingUploadNotificationChannelName,
        'channelDescription':
            AppStrings.trainingUploadNotificationChannelDescription,
        'cancelLabel': AppStrings.trainingCancel,
        'tasks': taskPayloads,
      });
    } catch (error) {
      debugPrint('Unable to sync training upload notifications: $error');
    }
  }

  void _ensureLifecycleObserverRegistered() {
    if (_didRegisterLifecycleObserver) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _didRegisterLifecycleObserver = true;
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    _isAppInForeground =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
  }
}
