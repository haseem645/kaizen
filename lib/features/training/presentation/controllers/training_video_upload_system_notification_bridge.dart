import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TrainingVideoUploadSystemNotificationBridge {
  TrainingVideoUploadSystemNotificationBridge._();

  static final TrainingVideoUploadSystemNotificationBridge instance =
      TrainingVideoUploadSystemNotificationBridge._();

  static const MethodChannel _channel = MethodChannel(
    'kaizenteams/training_video_upload_notifications',
  );

  bool _didClearNotifications = false;

  void queueSync(List<Map<String, Object?>> taskPayloads) {
    if (_didClearNotifications) {
      return;
    }

    _didClearNotifications = true;
    unawaited(_clearNotifications());
  }

  Future<List<int>> consumePendingCancelledTaskIds() async => const <int>[];

  Future<void> _clearNotifications() async {
    try {
      await _channel.invokeMethod<void>('clearTrainingUploadNotifications');
    } catch (error) {
      debugPrint('Unable to clear training upload notifications: $error');
    }
  }
}
