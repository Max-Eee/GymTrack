package com.gymtrack.gym_track

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.io.File

/**
 * Foreground service that keeps model downloads alive when the app is minimized.
 * Shows a persistent notification with download progress.
 */
class ModelDownloadService : Service() {

    companion object {
        private const val TAG = "ModelDownloadService"
        private const val CHANNEL_ID = "model_download_channel"
        private const val NOTIFICATION_ID = 1001

        // Actions
        const val ACTION_START_DOWNLOAD = "com.gymtrack.ACTION_START_DOWNLOAD"
        const val ACTION_CANCEL_DOWNLOAD = "com.gymtrack.ACTION_CANCEL_DOWNLOAD"

        // Extras
        const val EXTRA_MODEL_ID = "model_id"
        const val EXTRA_DOWNLOAD_URL = "download_url"
        const val EXTRA_MODEL_NAME = "model_name"

        // Broadcast actions for communicating back to Flutter
        const val BROADCAST_PROGRESS = "com.gymtrack.DOWNLOAD_PROGRESS"
        const val BROADCAST_COMPLETE = "com.gymtrack.DOWNLOAD_COMPLETE"
        const val BROADCAST_ERROR = "com.gymtrack.DOWNLOAD_ERROR"

        @Volatile
        var isRunning = false
            private set

        @Volatile
        var currentModelId: String? = null
            private set

        @Volatile
        var lastProgress: Map<String, Any>? = null
            private set

        // Listener for progress events (used by MainActivity to forward to Flutter)
        var progressListener: ((Map<String, Any>) -> Unit)? = null
        var completionListener: ((String, Boolean, String?) -> Unit)? = null
    }

    private var downloadJob: Job? = null
    private var downloader: ModelDownloader? = null
    private lateinit var prefs: SharedPreferences
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences("gemma_models", Context.MODE_PRIVATE)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_DOWNLOAD -> {
                val modelId = intent.getStringExtra(EXTRA_MODEL_ID) ?: return START_NOT_STICKY
                val downloadUrl = intent.getStringExtra(EXTRA_DOWNLOAD_URL) ?: return START_NOT_STICKY
                val modelName = intent.getStringExtra(EXTRA_MODEL_NAME) ?: modelId

                startForeground(modelId, modelName)
                startDownload(modelId, downloadUrl, modelName)
            }
            ACTION_CANCEL_DOWNLOAD -> {
                cancelCurrentDownload()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForeground(modelId: String, modelName: String) {
        val notification = buildNotification(modelName, "Preparing download...", 0, true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        isRunning = true
        currentModelId = modelId
    }

    private fun startDownload(modelId: String, downloadUrl: String, modelName: String) {
        // Cancel any existing download
        downloadJob?.cancel()
        downloader?.cancel()

        downloader = ModelDownloader(this) { downloadedBytes, totalBytes, speedBps ->
            val progressMap = mapOf(
                "modelId" to modelId,
                "downloadedMB" to (downloadedBytes / 1_000_000.0),
                "totalMB" to (totalBytes / 1_000_000.0),
                "speedMBps" to (speedBps / 1_000_000.0),
                "percent" to if (totalBytes > 0) (downloadedBytes.toDouble() / totalBytes.toDouble()) else 0.0
            )
            lastProgress = progressMap

            // Update notification
            val percent = if (totalBytes > 0) ((downloadedBytes.toDouble() / totalBytes.toDouble()) * 100).toInt() else 0
            val downloadedMB = downloadedBytes / 1_000_000.0
            val totalMB = totalBytes / 1_000_000.0
            val speedMBps = speedBps / 1_000_000.0
            val text = "${String.format("%.0f", downloadedMB)} / ${String.format("%.0f", totalMB)} MB  •  ${String.format("%.1f", speedMBps)} MB/s"
            updateNotification(modelName, text, percent, true)

            // Notify listeners (Flutter side)
            progressListener?.invoke(progressMap)
        }

        downloadJob = serviceScope.launch {
            try {
                Log.i(TAG, "Starting background download for $modelId")
                val modelFile = downloader?.downloadModel(downloadUrl, modelId)

                if (modelFile != null && modelFile.exists()) {
                    // Save to preferences
                    prefs.edit().apply {
                        putBoolean("${modelId}_downloaded", true)
                        putString("${modelId}_path", modelFile.absolutePath)
                        putLong("${modelId}_download_date", System.currentTimeMillis())
                        apply()
                    }

                    Log.i(TAG, "Download complete for $modelId")
                    withContext(Dispatchers.Main) {
                        updateNotification(modelName, "Download complete", 100, false)
                        completionListener?.invoke(modelId, true, null)
                    }
                } else {
                    Log.e(TAG, "Download failed for $modelId")
                    withContext(Dispatchers.Main) {
                        updateNotification(modelName, "Download failed", 0, false)
                        completionListener?.invoke(modelId, false, "Download failed")
                    }
                }
            } catch (e: CancellationException) {
                Log.i(TAG, "Download cancelled for $modelId")
                withContext(Dispatchers.Main) {
                    completionListener?.invoke(modelId, false, "Cancelled")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Download error for $modelId: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    updateNotification(modelName, "Download failed", 0, false)
                    completionListener?.invoke(modelId, false, e.message)
                }
            } finally {
                withContext(Dispatchers.Main) {
                    // Auto-dismiss notification after a delay for completion/error
                    delay(3000)
                    isRunning = false
                    currentModelId = null
                    lastProgress = null
                    stopSelf()
                }
            }
        }
    }

    private fun cancelCurrentDownload() {
        downloader?.cancel()
        downloadJob?.cancel()
        isRunning = false
        currentModelId = null
        lastProgress = null
    }

    override fun onDestroy() {
        cancelCurrentDownload()
        serviceScope.cancel()
        super.onDestroy()
    }

    // ── Notification helpers ──────────────────────────────────────

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Model Downloads",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows progress when downloading AI models"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(
        title: String,
        text: String,
        progress: Int,
        ongoing: Boolean
    ): Notification {
        // Cancel action
        val cancelIntent = Intent(this, ModelDownloadService::class.java).apply {
            action = ACTION_CANCEL_DOWNLOAD
        }
        val cancelPendingIntent = PendingIntent.getService(
            this, 0, cancelIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Tap to open app
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPendingIntent = if (openIntent != null) {
            PendingIntent.getActivity(
                this, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title)
            .setContentText(text)
            .setProgress(100, progress, progress == 0 && ongoing)
            .setOngoing(ongoing)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .apply {
                if (ongoing) addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancel", cancelPendingIntent)
                if (!ongoing) setSmallIcon(android.R.drawable.stat_sys_download_done)
                if (openPendingIntent != null) setContentIntent(openPendingIntent)
            }
            .build()
    }

    private fun updateNotification(title: String, text: String, progress: Int, ongoing: Boolean) {
        val notification = buildNotification(title, text, progress, ongoing)
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }
}
