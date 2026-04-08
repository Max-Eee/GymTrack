package com.gymtrack.gym_track

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File

class MainActivity: FlutterActivity() {
    private val GEMMA_CHANNEL = "com.gymtrack.gemma_litert"
    private val GEMMA_PROGRESS_CHANNEL = "com.gymtrack.gemma_litert_progress"
    private val GEMMA_STREAM_CHANNEL = "com.gymtrack.gemma_litert_stream"
    
    private lateinit var gemmaWrapper: GemmaLiteRTWrapper
    private lateinit var prefs: SharedPreferences
    
    private val downloadedModels = mutableSetOf<String>()
    private var activeModelId: String? = null
    
    private var progressEventSink: EventChannel.EventSink? = null
    private var streamEventSink: EventChannel.EventSink? = null

    // Track pending MethodChannel results for downloads started via service
    private val pendingDownloadResults = mutableMapOf<String, MethodChannel.Result>()

    // Pending download to start after notification permission is granted
    private var pendingDownloadIntent: Intent? = null
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize components
        gemmaWrapper = GemmaLiteRTWrapper(this)
        prefs = getSharedPreferences("gemma_models", Context.MODE_PRIVATE)
        
        // Restore downloaded models and active model from preferences
        restoreModelStates()

        // Wire up service listeners for progress & completion
        ModelDownloadService.progressListener = { progressMap ->
            progressEventSink?.success(progressMap)
        }
        ModelDownloadService.completionListener = { modelId, success, error ->
            if (success) {
                downloadedModels.add(modelId)
                // Re-read path from prefs (service saves it)
                val modelPath = prefs.getString("${modelId}_path", null)
                android.util.Log.i("GymTrack", "Service download SUCCESS for $modelId path=$modelPath")
            }
            val pendingResult = pendingDownloadResults.remove(modelId)
            if (pendingResult != null) {
                if (success) {
                    pendingResult.success(true)
                } else {
                    pendingResult.error("DOWNLOAD_FAILED", error ?: "Download failed", null)
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, GEMMA_PROGRESS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    progressEventSink = null
                }
            }
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, GEMMA_STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    streamEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    streamEventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GEMMA_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDownloadedModels" -> {
                    result.success(downloadedModels.toList())
                }
                "getActiveModel" -> {
                    result.success(activeModelId)
                }
                "downloadModel" -> {
                    val modelId = call.argument<String>("modelId")
                    val downloadUrl = call.argument<String>("downloadUrl")
                    
                    android.util.Log.i("GymTrack", "=== downloadModel called === modelId=$modelId url=$downloadUrl")
                    
                    if (modelId == null) {
                        result.error("INVALID_ARG", "Missing modelId", null)
                        return@setMethodCallHandler
                    }
                    
                    if (downloadUrl == null) {
                       result.error("INVALID_ARG", "Missing downloadUrl", null)
                       return@setMethodCallHandler
                    }
                    
                    // Store the pending result to resolve when service completes
                    pendingDownloadResults[modelId] = result
                    
                    // Build the service intent
                    val serviceIntent = Intent(this, ModelDownloadService::class.java).apply {
                        action = ModelDownloadService.ACTION_START_DOWNLOAD
                        putExtra(ModelDownloadService.EXTRA_MODEL_ID, modelId)
                        putExtra(ModelDownloadService.EXTRA_DOWNLOAD_URL, downloadUrl)
                        putExtra(ModelDownloadService.EXTRA_MODEL_NAME, "Downloading AI Model")
                    }
                    
                    // Request notification permission on Android 13+ before starting service
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                            != PackageManager.PERMISSION_GRANTED) {
                        pendingDownloadIntent = serviceIntent
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            NOTIFICATION_PERMISSION_REQUEST_CODE
                        )
                    } else {
                        startForegroundService(serviceIntent)
                    }
                }
                "cancelDownload" -> {
                     val modelId = call.argument<String>("modelId")
                     if (modelId != null) {
                         // Cancel via service
                         val cancelIntent = Intent(this, ModelDownloadService::class.java).apply {
                             action = ModelDownloadService.ACTION_CANCEL_DOWNLOAD
                         }
                         startService(cancelIntent)
                         pendingDownloadResults.remove(modelId)
                     }
                     result.success(null)
                }
                "activateModel" -> {
                     val modelId = call.argument<String>("modelId")
                     
                     if (modelId == null) {
                         result.error("INVALID_ARG", "Missing modelId", null)
                         return@setMethodCallHandler
                     }
                     
                     if (!downloadedModels.contains(modelId)) {
                         result.error("NOT_DOWNLOADED", "Model not downloaded", null)
                         return@setMethodCallHandler
                     }
                     
                     try {
                         // Verify model file exists
                         val modelPath = prefs.getString("${modelId}_path", null)
                         if (modelPath == null) {
                             result.error("NO_PATH", "Model path not found", null)
                             return@setMethodCallHandler
                         }
                         
                         val modelFile = File(modelPath)
                         if (!modelFile.exists()) {
                             result.error("FILE_NOT_FOUND", "Model file not found", null)
                             return@setMethodCallHandler
                         }
                         
                         // Just mark as active - don't load into memory yet (lazy loading)
                         // Model will be loaded on-demand during first inference
                         activeModelId = modelId
                         prefs.edit().putString("active_model_id", modelId).apply()
                         
                         android.util.Log.i("GymTrack", "Model $modelId set as active (lazy loading enabled)")
                         result.success(true)
                     } catch (e: Exception) {
                         result.error("ACTIVATION_ERROR", e.message, null)
                     }
                }
                "freeModel" -> {
                    gemmaWrapper.freeModel()
                    android.util.Log.i("GymTrack", "Model freed from memory (will auto-reload on next infer)")
                    result.success(true)
                }
                "infer" -> {
                    val prompt = call.argument<String>("prompt")
                    val modelId = call.argument<String>("modelId")
                    val systemInstruction = call.argument<String>("systemInstruction")
                    val audioBytes = call.argument<ByteArray>("audioBytes")
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    
                    if (prompt == null || modelId == null) {
                        result.error("INVALID_ARG", "Missing prompt or modelId", null)
                        return@setMethodCallHandler
                    }
                    if (modelId != activeModelId) {
                        result.error("NOT_ACTIVE", "Model is not active", null)
                        return@setMethodCallHandler
                    }
                    
                    if (!gemmaWrapper.isModelLoaded()) {
                        // Auto-load the active model if not yet in memory
                        val modelPath = prefs.getString("${modelId}_path", null)
                        if (modelPath != null && File(modelPath).exists()) {
                            android.util.Log.i("GymTrack", "Auto-loading model on infer: $modelId")
                            CoroutineScope(Dispatchers.IO).launch {
                                try {
                                    val loadStartTime = System.currentTimeMillis()
                                    val loaded = gemmaWrapper.loadModel(File(modelPath), modelId)
                                    val loadTime = System.currentTimeMillis() - loadStartTime
                                    if (loaded) {
                                        android.util.Log.i("GymTrack", "Auto-load succeeded in ${loadTime}ms, running inference...")
                                        val inferStartTime = System.currentTimeMillis()
                                        val response = gemmaWrapper.generateContentWithTimeout(
                                            prompt = prompt,
                                            systemInstruction = systemInstruction,
                                            imageBytes = imageBytes,
                                            audioBytes = audioBytes,
                                            timeoutMs = 120000
                                        )
                                        val inferTime = System.currentTimeMillis() - inferStartTime
                                        android.util.Log.i("GymTrack", "Inference completed in ${inferTime}ms")
                                        withContext(Dispatchers.Main) {
                                            if (response != null) {
                                                result.success(response)
                                            } else {
                                                result.error("GENERATION_TIMEOUT", "Inference timed out", null)
                                            }
                                        }
                                    } else {
                                        withContext(Dispatchers.Main) {
                                            result.error("LOAD_FAILED", "Failed to load model into memory", null)
                                        }
                                    }
                                } catch (e: Exception) {
                                    android.util.Log.e("GymTrack", "Auto-load+infer error: ${e.message}", e)
                                    withContext(Dispatchers.Main) {
                                        result.error("LOAD_FAILED", "Failed to load model: ${e.message}", null)
                                    }
                                }
                            }
                        } else {
                            result.error("FILE_NOT_FOUND", "Model file not found on disk", null)
                        }
                        return@setMethodCallHandler
                    }
                    
                    android.util.Log.i("GymTrack", "Infer: prompt=${prompt.take(100)} image=${imageBytes?.size ?: 0} bytes")
                    
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val inferStartTime = System.currentTimeMillis()
                            val response = gemmaWrapper.generateContentWithTimeout(
                                prompt = prompt,
                                systemInstruction = systemInstruction,
                                imageBytes = imageBytes,
                                audioBytes = audioBytes,
                                timeoutMs = 120000
                            )
                            val inferTime = System.currentTimeMillis() - inferStartTime
                            android.util.Log.i("GymTrack", "Inference completed in ${inferTime}ms")
                            
                            withContext(Dispatchers.Main) {
                                if (response != null) {
                                    result.success(response)
                                } else {
                                    result.error("GENERATION_TIMEOUT", "Inference timed out", null)
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("GENERATION_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "inferStream" -> {
                    val prompt = call.argument<String>("prompt")
                    val modelId = call.argument<String>("modelId")
                    val systemInstruction = call.argument<String>("systemInstruction")
                    
                    if (prompt == null || modelId == null) {
                        result.error("INVALID_ARG", "Missing prompt or modelId", null)
                        return@setMethodCallHandler
                    }
                    if (modelId != activeModelId) {
                        result.error("NOT_ACTIVE", "Model is not active", null)
                        return@setMethodCallHandler
                    }
                    
                    val sink = streamEventSink
                    
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            // Auto-load if needed
                            if (!gemmaWrapper.isModelLoaded()) {
                                val modelPath = prefs.getString("${modelId}_path", null)
                                if (modelPath != null && File(modelPath).exists()) {
                                    withContext(Dispatchers.Main) {
                                        sink?.success(mapOf("type" to "status", "message" to "Loading model..."))
                                    }
                                    val loaded = gemmaWrapper.loadModel(File(modelPath), modelId)
                                    if (!loaded) {
                                        withContext(Dispatchers.Main) {
                                            result.error("LOAD_FAILED", "Failed to load model", null)
                                        }
                                        return@launch
                                    }
                                }
                            }
                            
                            withContext(Dispatchers.Main) {
                                sink?.success(mapOf("type" to "status", "message" to "Thinking..."))
                            }
                            
                            val response = gemmaWrapper.generateContentStreaming(
                                prompt = prompt,
                                systemInstruction = systemInstruction,
                                onToken = { token ->
                                    CoroutineScope(Dispatchers.Main).launch {
                                        sink?.success(mapOf("type" to "token", "data" to token))
                                    }
                                }
                            )
                            
                            withContext(Dispatchers.Main) {
                                sink?.success(mapOf("type" to "done", "data" to (response ?: "")))
                                if (response != null) {
                                    result.success(response)
                                } else {
                                    result.error("GENERATION_TIMEOUT", "Inference timed out", null)
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                sink?.success(mapOf("type" to "error", "message" to (e.message ?: "Unknown error")))
                                result.error("GENERATION_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    /**
     * Restore downloaded models and active model from SharedPreferences
     */
    private fun restoreModelStates() {
        // Restore downloaded models
        val allPrefs = prefs.all
        for ((key, value) in allPrefs) {
            if (key.endsWith("_downloaded") && value == true) {
                val modelId = key.removeSuffix("_downloaded")
                val modelPath = prefs.getString("${modelId}_path", null)
                
                // Verify file still exists
                if (modelPath != null && File(modelPath).exists()) {
                    downloadedModels.add(modelId)
                } else {
                    // Clean up invalid entry
                    prefs.edit().remove(key).remove("${modelId}_path").remove("${modelId}_download_date").apply()
                }
            }
        }
        
        // Restore active model ID (lazy loading - no immediate load)
        val savedActiveModel = prefs.getString("active_model_id", null)
        if (savedActiveModel != null && downloadedModels.contains(savedActiveModel)) {
            val modelPath = prefs.getString("${savedActiveModel}_path", null)
            if (modelPath != null && File(modelPath).exists()) {
                activeModelId = savedActiveModel
                android.util.Log.i("GymTrack", "Restored active model: $savedActiveModel (will load on-demand)")
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            // Start the download regardless of whether permission was granted
            // (service works without notifications, just won't show progress in status bar)
            pendingDownloadIntent?.let { intent ->
                startForegroundService(intent)
            }
            pendingDownloadIntent = null
        }
    }
}
