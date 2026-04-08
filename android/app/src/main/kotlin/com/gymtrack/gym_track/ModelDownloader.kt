package com.gymtrack.gym_track

import android.content.Context
import android.util.Log
import kotlinx.coroutines.*
import okhttp3.*
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest

/**
 * Handles downloading Gemma model files with progress tracking and resume capability
 */
class ModelDownloader(
    private val context: Context,
    private val progressCallback: (downloadedBytes: Long, totalBytes: Long, speedBps: Double) -> Unit
) {
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(120, java.util.concurrent.TimeUnit.SECONDS)
        .writeTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .followRedirects(true)
        .followSslRedirects(true)
        .build()
    
    companion object {
        private const val TAG = "ModelDownloader"
        // Kaggle API token for model downloads (only needed for google/ repos with Gemma license)
        private const val KAGGLE_API_TOKEN = "KGAT_af2380191266777ee9db9bc043d86fc0"
    }
    
    private var currentCall: Call? = null
    
    /**
     * Download a model file from URL with resume capability
     * @param url The download URL
     * @param modelId The model identifier (e.g., "gemma-4-e2b-it")
     * @return File object pointing to the downloaded model, or null if failed
     */
    suspend fun downloadModel(url: String, modelId: String): File? = withContext(Dispatchers.IO) {
        Log.i(TAG, "=== DOWNLOAD START ===")
        Log.i(TAG, "modelId=$modelId")
        Log.i(TAG, "url=$url")
        
        val modelsDir = File(context.filesDir, "models")
        if (!modelsDir.exists()) {
            val created = modelsDir.mkdirs()
            Log.i(TAG, "Created models dir: $created path=${modelsDir.absolutePath}")
        }
        
        // Extract filename from URL
        val fileName = url.substringAfterLast("/")
        val modelFile = File(modelsDir, fileName)
        val tempFile = File(modelsDir, "$fileName.tmp")
        
        Log.i(TAG, "Target file: ${modelFile.absolutePath}")
        Log.i(TAG, "Temp file: ${tempFile.absolutePath}")
        
        // Check if already fully downloaded
        if (modelFile.exists()) {
            Log.i(TAG, "Model already exists! Size=${modelFile.length()} bytes")
            return@withContext modelFile
        }
        
        var downloadedBytes = if (tempFile.exists()) tempFile.length() else 0L
        Log.i(TAG, "Resume from byte: $downloadedBytes (temp exists=${tempFile.exists()})")
        
        try {
            // Only add auth header for google/ repos that need Gemma license
            val needsAuth = url.contains("/google/") 
            Log.i(TAG, "Needs auth: $needsAuth")
            
            val request = Request.Builder()
                .url(url)
                .apply {
                    if (needsAuth) {
                        addHeader("Authorization", "Bearer $KAGGLE_API_TOKEN")
                        Log.i(TAG, "Added Authorization header")
                    }
                    if (downloadedBytes > 0) {
                        addHeader("Range", "bytes=$downloadedBytes-")
                        Log.i(TAG, "Added Range header: bytes=$downloadedBytes-")
                    }
                }
                .build()
            
            Log.i(TAG, "Executing HTTP request...")
            currentCall = client.newCall(request)
            val response = currentCall?.execute()
            
            Log.i(TAG, "Response: code=${response?.code} message=${response?.message}")
            Log.i(TAG, "Response headers: ${response?.headers}")
            
            if (response == null || !response.isSuccessful) {
                val errorBody = response?.body?.string()?.take(500) ?: "null"
                Log.e(TAG, "Download FAILED! code=${response?.code} body=$errorBody")
                response?.close()
                return@withContext null
            }
            
            val totalBytes = if (response.code == 206) {
                val contentRange = response.header("Content-Range")
                Log.i(TAG, "Content-Range: $contentRange")
                contentRange?.substringAfter("/")?.toLongOrNull() ?: (downloadedBytes + (response.body?.contentLength() ?: 0))
            } else {
                response.body?.contentLength() ?: 0
            }
            
            Log.i(TAG, "Total bytes to download: $totalBytes (${totalBytes / 1_000_000} MB)")
            
            if (totalBytes <= 0L) {
                Log.e(TAG, "Invalid total bytes: $totalBytes - Content-Length: ${response.body?.contentLength()}")
            }
            
            val inputStream = response.body?.byteStream()
            if (inputStream == null) {
                Log.e(TAG, "No response body / input stream!")
                response.close()
                return@withContext null
            }
            
            Log.i(TAG, "Starting byte stream download...")
            
            FileOutputStream(tempFile, downloadedBytes > 0).use { outputStream ->
                val buffer = ByteArray(8192)
                var bytesRead: Int
                var lastProgressTime = System.currentTimeMillis()
                var bytesReadSinceLastProgress = 0L
                var totalChunksRead = 0
                
                while (isActive) {
                    bytesRead = inputStream.read(buffer)
                    if (bytesRead == -1) break
                    
                    outputStream.write(buffer, 0, bytesRead)
                    downloadedBytes += bytesRead
                    bytesReadSinceLastProgress += bytesRead
                    totalChunksRead++
                    
                    // Log first few chunks for debugging
                    if (totalChunksRead <= 3) {
                        Log.i(TAG, "Chunk #$totalChunksRead: read $bytesRead bytes, total=$downloadedBytes")
                    }
                    
                    val currentTime = System.currentTimeMillis()
                    val timeDiff = currentTime - lastProgressTime
                    
                    // Update progress every 500ms
                    if (timeDiff >= 500) {
                        val speedBps = (bytesReadSinceLastProgress.toDouble() / timeDiff) * 1000.0
                        val pct = if (totalBytes > 0) (downloadedBytes.toDouble() / totalBytes * 100) else 0.0
                        Log.d(TAG, "Progress: ${downloadedBytes / 1_000_000} MB / ${totalBytes / 1_000_000} MB (${pct.toInt()}%) speed=${speedBps / 1_000_000} MB/s")
                        withContext(Dispatchers.Main) {
                            progressCallback(downloadedBytes, totalBytes, speedBps)
                        }
                        lastProgressTime = currentTime
                        bytesReadSinceLastProgress = 0
                    }
                }
            }
            
            inputStream.close()
            response.close()
            
            // Move temp file to final destination
            if (isActive && tempFile.exists()) {
                val renamed = tempFile.renameTo(modelFile)
                Log.i(TAG, "=== DOWNLOAD COMPLETE === renamed=$renamed finalSize=${modelFile.length()} bytes")
                
                // Final progress update
                withContext(Dispatchers.Main) {
                    progressCallback(totalBytes, totalBytes, 0.0)
                }
                
                return@withContext modelFile
            }
            
            Log.w(TAG, "Download cancelled or temp file missing. isActive=$isActive tempExists=${tempFile.exists()}")
            return@withContext null
            
        } catch (e: IOException) {
            Log.e(TAG, "IOException during download: ${e.message}", e)
            return@withContext null
        } catch (e: Exception) {
            Log.e(TAG, "Exception during download: ${e.message}", e)
            return@withContext null
        }
    }
    
    /**
     * Cancel the current download
     */
    fun cancel() {
        currentCall?.cancel()
    }
    
    /**
     * Verify model file integrity using SHA-256 checksum
     */
    fun verifyModelChecksum(modelFile: File, expectedChecksum: String): Boolean {
        if (!modelFile.exists()) return false
        
        try {
            val digest = MessageDigest.getInstance("SHA-256")
            modelFile.inputStream().use { input ->
                val buffer = ByteArray(8192)
                var bytesRead: Int
                while (input.read(buffer).also { bytesRead = it } != -1) {
                    digest.update(buffer, 0, bytesRead)
                }
            }
            
            val hash = digest.digest().joinToString("") { "%02x".format(it) }
            return hash.equals(expectedChecksum, ignoreCase = true)
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Get the model file if it exists (checks multiple extensions)
     */
    fun getModelFile(modelId: String): File? {
        val modelsDir = File(context.filesDir, "models")
        val extensions = listOf("litertlm", "task", "bin")
        for (ext in extensions) {
            val f = File(modelsDir, "$modelId.$ext")
            if (f.exists()) return f
        }
        return null
    }
    
    /**
     * Delete a model file
     */
    fun deleteModel(modelId: String): Boolean {
        val modelsDir = File(context.filesDir, "models")
        val extensions = listOf("litertlm", "task", "bin")
        var deleted = false
        for (ext in extensions) {
            val f = File(modelsDir, "$modelId.$ext")
            if (f.exists()) deleted = f.delete() || deleted
            val tmp = File(modelsDir, "$modelId.$ext.tmp")
            if (tmp.exists()) deleted = tmp.delete() || deleted
        }
        return deleted
    }
}
