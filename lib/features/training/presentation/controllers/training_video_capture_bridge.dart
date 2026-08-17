import 'dart:io';

import 'package:flutter/services.dart';

class TrainingVideoCaptureBridge {
  TrainingVideoCaptureBridge._();

  static final TrainingVideoCaptureBridge instance =
      TrainingVideoCaptureBridge._();

  static const MethodChannel _channel = MethodChannel(
    'kaizenteams/training_video_capture',
  );

  Future<void> restorePendingCaptureIfNeeded() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod<void>('restorePendingTrainingVideoCapture');
  }

  Future<File?> captureVideoWithSystemCamera() async {
    if (!Platform.isAndroid) {
      return null;
    }

    final path = await _channel.invokeMethod<String>(
      'captureTrainingVideoWithSystemCamera',
    );
    if (path == null) {
      return null;
    }

    final resolvedPath = path.trim();
    if (resolvedPath.isEmpty) {
      return null;
    }

    return File(resolvedPath);
  }
}
