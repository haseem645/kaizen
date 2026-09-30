package com.kaizenteam

import android.content.Intent
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var trainingVideoCaptureBridge: TrainingVideoCaptureBridge
    private var isVideoFullscreen = false
    private var previousSystemBarsBehavior: Int? = null

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VIDEO_FULLSCREEN_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "setFullscreen") {
                isVideoFullscreen = call.argument<Boolean>("enabled") == true
                applyVideoFullscreen()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && isVideoFullscreen) {
            applyVideoFullscreen()
        }
    }

    private fun applyVideoFullscreen() {
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        if (isVideoFullscreen) {
            if (previousSystemBarsBehavior == null) {
                previousSystemBarsBehavior = controller.systemBarsBehavior
            }
            controller.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            controller.hide(WindowInsetsCompat.Type.systemBars())
        } else {
            previousSystemBarsBehavior?.let { controller.systemBarsBehavior = it }
            previousSystemBarsBehavior = null
            controller.show(WindowInsetsCompat.Type.systemBars())
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
        const val VIDEO_FULLSCREEN_CHANNEL = "kaizenteams/video_fullscreen"
        const val TRAINING_VIDEO_CAPTURE_CHANNEL =
            "kaizenteams/training_video_capture"
    }
}
