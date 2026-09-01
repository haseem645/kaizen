package com.kaizenteam

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var trainingUploadNotificationBridge: TrainingUploadNotificationBridge
    private lateinit var trainingVideoCaptureBridge: TrainingVideoCaptureBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (!this::trainingUploadNotificationBridge.isInitialized) {
            trainingUploadNotificationBridge = TrainingUploadNotificationBridge(this)
        }
        if (!this::trainingVideoCaptureBridge.isInitialized) {
            trainingVideoCaptureBridge = TrainingVideoCaptureBridge(this)
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TRAINING_UPLOAD_NOTIFICATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestTrainingUploadNotificationPermission" -> {
                    trainingUploadNotificationBridge.requestPermissionIfNeeded()
                    result.success(null)
                }

                "syncTrainingUploadNotifications" -> {
                    val arguments = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                    trainingUploadNotificationBridge.syncNotifications(arguments)
                    result.success(null)
                }

                "clearTrainingUploadNotifications" -> {
                    trainingUploadNotificationBridge.clearNotifications()
                    result.success(null)
                }

                "consumePendingCancelledTrainingUploadTaskIds" -> {
                    result.success(
                        trainingUploadNotificationBridge.consumePendingCancelledTaskIds(),
                    )
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TRAINING_VIDEO_CAPTURE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "captureTrainingVideoWithSystemCamera" -> {
                    trainingVideoCaptureBridge.captureVideoWithSystemCamera(result)
                }

                "restorePendingTrainingVideoCapture" -> {
                    trainingVideoCaptureBridge.restorePendingCaptureIfNeeded(result)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        if (this::trainingVideoCaptureBridge.isInitialized &&
            trainingVideoCaptureBridge.handleActivityResult(requestCode, resultCode, data)
        ) {
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }

    private companion object {
        const val TRAINING_UPLOAD_NOTIFICATION_CHANNEL =
            "kaizenteams/training_video_upload_notifications"
        const val TRAINING_VIDEO_CAPTURE_CHANNEL =
            "kaizenteams/training_video_capture"
    }
}
