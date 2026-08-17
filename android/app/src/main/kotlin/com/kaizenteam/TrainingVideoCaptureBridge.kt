package com.kaizenteam

import android.app.Activity
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class TrainingVideoCaptureBridge(
    private val activity: FlutterActivity,
) {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingCaptureUri: Uri? = null

    fun captureVideoWithSystemCamera(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error(
                "capture_already_active",
                "A training video capture is already in progress.",
                null,
            )
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error(
                "legacy_android_capture_fallback",
                "Use the default camera capture flow on Android 9 and below.",
                null,
            )
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            result.error(
                "modern_android_capture_fallback",
                "Use the default camera capture flow on Android 15 and above.",
                null,
            )
            return
        }

        try {
            cleanupAbandonedPendingCapture()
        } catch (error: Throwable) {
            result.error(
                "capture_cleanup_failed",
                error.message ?: "Unable to prepare video capture.",
                null,
            )
            return
        }

        val intent = Intent(MediaStore.ACTION_VIDEO_CAPTURE)
        val cameraActivity = intent.resolveActivity(activity.packageManager)
        if (cameraActivity == null) {
            result.error(
                "no_available_camera",
                "No camera application is available for video capture.",
                null,
            )
            return
        }

        val captureUri =
            try {
                createCaptureUri()
            } catch (error: Throwable) {
                result.error(
                    "capture_destination_unavailable",
                    error.message ?: "Unable to prepare a gallery destination for the recorded video.",
                    null,
                )
                return
            }
        if (captureUri == null) {
            result.error(
                "capture_destination_unavailable",
                "Unable to prepare a gallery destination for the recorded video.",
                null,
            )
            return
        }

        pendingResult = result
        pendingCaptureUri = captureUri
        persistPendingCaptureUri(captureUri)

        intent.putExtra(MediaStore.EXTRA_OUTPUT, captureUri)
        intent.addFlags(
            Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )
        intent.clipData = ClipData.newRawUri("", captureUri)

        try {
            activity.startActivityForResult(intent, REQUEST_CODE_CAPTURE_TRAINING_VIDEO)
        } catch (error: SecurityException) {
            deleteUri(captureUri)
            clearPendingCapture()
            result.error(
                "camera_denied",
                error.message ?: "Camera permission is required to record a video.",
                null,
            )
        } catch (error: Throwable) {
            deleteUri(captureUri)
            clearPendingCapture()
            result.error(
                "camera_launch_failed",
                error.message ?: "Unable to launch the system camera.",
                null,
            )
        }
    }

    fun restorePendingCaptureIfNeeded(result: MethodChannel.Result) {
        val persistedUri = readPersistedPendingCaptureUri()
        clearPendingCapture()

        if (persistedUri == null) {
            result.success(null)
            return
        }

        val resolvedUri = resolveCompletedCaptureUri(persistedUri)
        if (resolvedUri == null) {
            deleteUri(persistedUri)
            result.success(null)
            return
        }

        cleanupUnusedPendingUris(
            resolvedUri = resolvedUri,
            candidateUris = listOf(persistedUri),
        )
        finalizeCaptureUri(resolvedUri)
        result.success(null)
    }

    fun handleActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != REQUEST_CODE_CAPTURE_TRAINING_VIDEO) {
            return false
        }

        val result = pendingResult
        val inMemoryCaptureUri = pendingCaptureUri
        val persistedCaptureUri = readPersistedPendingCaptureUri()
        val resolvedCaptureUri =
            if (resultCode == Activity.RESULT_OK) {
                resolveCompletedCaptureUri(
                    inMemoryCaptureUri,
                    data?.data,
                    persistedCaptureUri,
                )
            } else {
                null
            }
        clearPendingCapture()

        if (resolvedCaptureUri != null) {
            cleanupUnusedPendingUris(
                resolvedUri = resolvedCaptureUri,
                candidateUris = listOf(inMemoryCaptureUri, persistedCaptureUri),
            )
            finalizeCaptureUri(resolvedCaptureUri)
        } else {
            cleanupCandidateUris(inMemoryCaptureUri, persistedCaptureUri)
        }

        if (result == null) {
            return true
        }

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return true
        }

        if (resolvedCaptureUri == null) {
            result.error(
                "captured_video_unavailable",
                "Recorded video could not be prepared.",
                null,
            )
            return true
        }

        val cachedFile = copyUriToCacheFile(resolvedCaptureUri)
        if (cachedFile == null) {
            result.error(
                "capture_copy_failed",
                "Recorded video could not be prepared for upload.",
                null,
            )
            return true
        }

        result.success(cachedFile.absolutePath)
        return true
    }

    private fun createCaptureUri(): Uri? {
        val values =
            ContentValues().apply {
                put(
                    MediaStore.Video.Media.DISPLAY_NAME,
                    "training_video_${System.currentTimeMillis()}.mp4",
                )
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(
                        MediaStore.Video.Media.RELATIVE_PATH,
                        "${Environment.DIRECTORY_MOVIES}/Kaizen",
                    )
                    put(MediaStore.Video.Media.IS_PENDING, 1)
                }
            }

        val collectionUri =
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        return activity.contentResolver.insert(collectionUri, values)
    }

    private fun copyUriToCacheFile(uri: Uri): File? {
        val inputStream = activity.contentResolver.openInputStream(uri) ?: return null
        val outputFile =
            File.createTempFile(
                "training_video_${System.currentTimeMillis()}",
                ".mp4",
                activity.cacheDir,
            )

        return try {
            inputStream.use { input ->
                FileOutputStream(outputFile).use { output ->
                    val copiedBytes = input.copyTo(output)
                    if (copiedBytes <= 0L) {
                        outputFile.delete()
                        null
                    } else {
                        outputFile
                    }
                }
            }
        } catch (_: Throwable) {
            outputFile.delete()
            null
        }
    }

    private fun cleanupAbandonedPendingCapture() {
        val pendingUri = readPersistedPendingCaptureUri() ?: return
        clearPersistedPendingCaptureUri()

        val resolvedUri = resolveCompletedCaptureUri(pendingUri)
        if (resolvedUri != null) {
            cleanupUnusedPendingUris(
                resolvedUri = resolvedUri,
                candidateUris = listOf(pendingUri),
            )
            finalizeCaptureUri(resolvedUri)
            return
        }

        deleteUri(pendingUri)
    }

    private fun resolveCompletedCaptureUri(vararg candidateUris: Uri?): Uri? {
        val resolvedCandidates = distinctCandidateUris(*candidateUris)
        for (candidateUri in resolvedCandidates) {
            if (isPlayableVideo(candidateUri)) {
                return candidateUri
            }
        }

        for (candidateUri in resolvedCandidates) {
            if (hasBinaryContent(candidateUri) && isVideoContent(candidateUri)) {
                return candidateUri
            }
        }

        return null
    }

    private fun cleanupCandidateUris(vararg candidateUris: Uri?) {
        distinctCandidateUris(*candidateUris).forEach(::deleteUri)
    }

    private fun cleanupUnusedPendingUris(
        resolvedUri: Uri,
        candidateUris: List<Uri?>,
    ) {
        for (candidateUri in distinctCandidateUris(*candidateUris.toTypedArray())) {
            if (!urisMatch(candidateUri, resolvedUri)) {
                deleteUri(candidateUri)
            }
        }
    }

    private fun distinctCandidateUris(vararg candidateUris: Uri?): List<Uri> {
        val seenValues = LinkedHashSet<String>()
        val distinctUris = ArrayList<Uri>()
        for (candidateUri in candidateUris) {
            val serializedValue = candidateUri?.toString()?.trim() ?: continue
            if (serializedValue.isEmpty() || !seenValues.add(serializedValue)) {
                continue
            }
            distinctUris.add(candidateUri)
        }

        return distinctUris
    }

    private fun urisMatch(
        firstUri: Uri?,
        secondUri: Uri?,
    ): Boolean = firstUri?.toString() == secondUri?.toString()

    private fun finalizeCaptureUri(uri: Uri) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return
        }

        try {
            val values =
                ContentValues().apply {
                    put(MediaStore.Video.Media.IS_PENDING, 0)
                }
            activity.contentResolver.update(uri, values, null, null)
        } catch (_: Throwable) {
        }
    }

    private fun hasBinaryContent(uri: Uri): Boolean {
        val inputStream = activity.contentResolver.openInputStream(uri) ?: return false
        return try {
            inputStream.use { input -> input.read() != -1 }
        } catch (_: Throwable) {
            false
        }
    }

    private fun isVideoContent(uri: Uri): Boolean {
        val contentType =
            try {
                activity.contentResolver.getType(uri)
            } catch (_: Throwable) {
                null
            }
        return contentType?.startsWith("video/") == true
    }

    private fun isPlayableVideo(uri: Uri): Boolean {
        if (!hasBinaryContent(uri)) {
            return false
        }

        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(activity, uri)
            val durationMs =
                retriever
                    .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                    ?.toLongOrNull() ?: 0L
            durationMs > 0L
        } catch (_: Throwable) {
            false
        } finally {
            try {
                retriever.release()
            } catch (_: Throwable) {
            }
        }
    }

    private fun deleteUri(uri: Uri) {
        try {
            activity.contentResolver.delete(uri, null, null)
        } catch (_: Throwable) {
        }
    }

    private fun persistPendingCaptureUri(uri: Uri) {
        preferences.edit().putString(PENDING_CAPTURE_URI_KEY, uri.toString()).apply()
    }

    private fun readPersistedPendingCaptureUri(): Uri? {
        val rawValue = preferences.getString(PENDING_CAPTURE_URI_KEY, null) ?: return null
        return Uri.parse(rawValue)
    }

    private fun clearPersistedPendingCaptureUri() {
        preferences.edit().remove(PENDING_CAPTURE_URI_KEY).apply()
    }

    private fun clearPendingCapture() {
        pendingResult = null
        pendingCaptureUri = null
        clearPersistedPendingCaptureUri()
    }

    private val preferences
        get() =
            activity.getSharedPreferences(
                PREFERENCES_NAME,
                Activity.MODE_PRIVATE,
            )

    companion object {
        private const val REQUEST_CODE_CAPTURE_TRAINING_VIDEO = 9152
        private const val PREFERENCES_NAME = "training_video_capture_bridge"
        private const val PENDING_CAPTURE_URI_KEY = "pending_capture_uri"
    }
}
