package com.kaizenteam

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var trainingVideoCaptureBridge: TrainingVideoCaptureBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (!this::trainingVideoCaptureBridge.isInitialized) {
            trainingVideoCaptureBridge = TrainingVideoCaptureBridge(this)
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
        const val TRAINING_VIDEO_CAPTURE_CHANNEL =
            "kaizenteams/training_video_capture"
    }
}
