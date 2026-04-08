package com.gymtrack.gym_track

import android.content.Context
import android.util.Log
import com.google.ai.edge.litertlm.*
import kotlinx.coroutines.*
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Wrapper for LiteRT-LM Engine.
 * Based on Google AI Edge Gallery's LlmChatModelHelper implementation.
 */
class GemmaLiteRTWrapper(private val context: Context) {
    companion object {
        private const val TAG = "GemmaLiteRTWrapper"
        private const val MAX_NUM_TOKENS = 1024
    }
    
    private var engine: Engine? = null
    private var conversation: Conversation? = null
    private var activeModelId: String? = null
    private var activeModelFile: File? = null
    private var usingGpu: Boolean = false
    
    /**
     * Load a model from file into memory.
     * Matches Google AI Edge Gallery's engine initialization pattern.
     */
    suspend fun loadModel(modelFile: File, modelId: String): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.i(TAG, "Loading model: $modelId (${modelFile.length() / 1_000_000} MB)")
            
            // Unload current model first
            unloadModel()
            System.gc()
            
            var newEngine: Engine? = null
            
            // Try GPU first (same as Gallery: preferredBackend = Backend.GPU())
            try {
                val gpuConfig = EngineConfig(
                    modelPath = modelFile.absolutePath,
                    backend = Backend.GPU(),
                    visionBackend = Backend.GPU(),
                    audioBackend = Backend.CPU(),
                    maxNumTokens = MAX_NUM_TOKENS,
                    cacheDir = context.cacheDir.path
                )
                Log.i(TAG, "Engine config: GPU backend, visionBackend=GPU, maxNumTokens=$MAX_NUM_TOKENS, cacheDir=${context.cacheDir.path}")
                newEngine = Engine(gpuConfig)
                newEngine.initialize()
                Log.i(TAG, "GPU backend initialized successfully")
                usingGpu = true
            } catch (gpuErr: Throwable) {
                Log.w(TAG, "GPU backend failed: ${gpuErr.message}, falling back to CPU...")
                try { newEngine?.close() } catch (_: Exception) {}
                newEngine = null
                usingGpu = false
                System.gc()
                
                val cpuConfig = EngineConfig(
                    modelPath = modelFile.absolutePath,
                    backend = Backend.CPU(),
                    visionBackend = Backend.CPU(),
                    audioBackend = Backend.CPU(),
                    maxNumTokens = MAX_NUM_TOKENS,
                    cacheDir = context.cacheDir.path
                )
                Log.i(TAG, "Engine config: CPU fallback, maxNumTokens=$MAX_NUM_TOKENS")
                newEngine = Engine(cpuConfig)
                newEngine.initialize()
                Log.i(TAG, "CPU backend initialized successfully")
            }
            
            engine = newEngine
            activeModelId = modelId
            activeModelFile = modelFile
            
            Log.i(TAG, "Model loaded: $modelId (GPU=$usingGpu)")
            true
        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "OOM while loading model", e)
            cleanup()
            false
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to load model: ${e.message}", e)
            cleanup()
            false
        }
    }
    
    private fun cleanup() {
        try { conversation?.close() } catch (_: Exception) {}
        try { engine?.close() } catch (_: Exception) {}
        conversation = null
        engine = null
        activeModelId = null
        activeModelFile = null
        usingGpu = false
        System.gc()
    }
    
    fun unloadModel() {
        cleanup()
    }

    /**
     * Free the engine from memory but keep model info so it can auto-reload.
     */
    fun freeModel() {
        try {
            conversation?.close()
            engine?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing engine: ${e.message}")
        }
        conversation = null
        engine = null
        usingGpu = false
        System.gc()
        Log.i(TAG, "Model freed from memory (activeModelFile kept for auto-reload)")
    }
    
    fun isModelLoaded(): Boolean = engine != null
    fun getActiveModelId(): String? = activeModelId

    /**
     * Generate content with streaming token callback.
     * Calls onToken for each token as it arrives.
     */
    suspend fun generateContentStreaming(
        prompt: String,
        systemInstruction: String? = null,
        imageBytes: ByteArray? = null,
        audioBytes: ByteArray? = null,
        onToken: (String) -> Unit
    ): String? = withContext(Dispatchers.IO) {
        val eng = engine ?: return@withContext null
        
        try {
            Log.i(TAG, "Streaming: prompt=${prompt.length} chars")
            
            try { conversation?.close() } catch (_: Exception) {}
            conversation = null
            
            val conversationConfig = ConversationConfig(
                samplerConfig = SamplerConfig(
                    topK = 1,
                    topP = 1.0,
                    temperature = 0.0
                ),
                systemInstruction = if (systemInstruction != null) {
                    Contents.of(systemInstruction)
                } else null
            )
            
            val conv = eng.createConversation(conversationConfig)
            conversation = conv
            
            val contents = mutableListOf<Content>()
            if (imageBytes != null && imageBytes.isNotEmpty()) {
                contents.add(Content.ImageBytes(imageBytes))
            }
            if (audioBytes != null && audioBytes.isNotEmpty()) {
                contents.add(Content.AudioBytes(audioBytes))
            }
            contents.add(Content.Text(prompt))
            
            val resultBuilder = StringBuilder()
            val latch = CountDownLatch(1)
            var errorMessage: String? = null
            
            conv.sendMessageAsync(
                Contents.of(contents),
                object : MessageCallback {
                    override fun onMessage(message: Message) {
                        val token = message.toString()
                        resultBuilder.append(token)
                        onToken(token)
                    }
                    
                    override fun onDone() {
                        latch.countDown()
                    }
                    
                    override fun onError(throwable: Throwable) {
                        Log.e(TAG, "Streaming callback error", throwable)
                        errorMessage = throwable.message
                        latch.countDown()
                    }
                }
            )
            
            val completed = latch.await(90, TimeUnit.SECONDS)
            
            if (!completed) {
                Log.w(TAG, "Streaming timed out after 90s")
                try { conv.cancelProcess() } catch (_: Exception) {}
                try { conv.close() } catch (_: Exception) {}
                conversation = null
                // Return what we have so far
                val partial = resultBuilder.toString().trim()
                return@withContext if (partial.isNotEmpty()) partial else null
            }
            
            try { conv.close() } catch (_: Exception) {}
            conversation = null
            
            if (errorMessage != null) return@withContext null
            
            val text = resultBuilder.toString()
            val cleaned = text
                .replace(Regex("<\\|?turn\\|?>|<turn\\|>"), "")
                .replace(Regex("<\\|?model\\|?>"), "")
                .replace(Regex("<\\|?user\\|?>"), "")
                .replace(Regex("</?eos>"), "")
                .trim()
            cleaned
        } catch (e: Exception) {
            Log.e(TAG, "Streaming generation failed: ${e.message}", e)
            try { conversation?.close() } catch (_: Exception) {}
            conversation = null
            null
        }
    }

    /**
     * Generate content using sendMessageAsync with callbacks.
     * Same pattern as Google AI Edge Gallery's runInference.
     * Uses systemInstruction in ConversationConfig.
     */
    suspend fun generateContent(
        prompt: String,
        systemInstruction: String? = null,
        imageBytes: ByteArray? = null,
        audioBytes: ByteArray? = null
    ): String? = withContext(Dispatchers.IO) {
        val eng = engine ?: return@withContext null
        
        try {
            Log.i(TAG, "Generating: prompt=${prompt.length} chars, image=${imageBytes?.size ?: 0} bytes")
            
            // Close previous conversation
            try { conversation?.close() } catch (_: Exception) {}
            conversation = null
            
            // Build ConversationConfig matching Gallery pattern
            val conversationConfig = ConversationConfig(
                samplerConfig = SamplerConfig(
                    topK = 1,
                    topP = 1.0,
                    temperature = 0.0
                ),
                systemInstruction = if (systemInstruction != null) {
                    Contents.of(systemInstruction)
                } else null
            )
            
            val conv = eng.createConversation(conversationConfig)
            conversation = conv
            Log.i(TAG, "Conversation created (topK=1, temp=0, systemInstruction=${systemInstruction != null})")
            
            // Build content list (same as Gallery: images first, then text)
            val contents = mutableListOf<Content>()
            if (imageBytes != null && imageBytes.isNotEmpty()) {
                contents.add(Content.ImageBytes(imageBytes))
                Log.i(TAG, "Added image content: ${imageBytes.size} bytes")
            }
            if (audioBytes != null && audioBytes.isNotEmpty()) {
                contents.add(Content.AudioBytes(audioBytes))
                Log.i(TAG, "Added audio content: ${audioBytes.size} bytes")
            }
            // Add text AFTER image/audio (Gallery pattern: "add text after image and audio for accurate last token")
            contents.add(Content.Text(prompt))
            
            // Use sendMessageAsync with callback (same as Gallery)
            val resultBuilder = StringBuilder()
            val latch = CountDownLatch(1)
            var errorMessage: String? = null
            
            conv.sendMessageAsync(
                Contents.of(contents),
                object : MessageCallback {
                    override fun onMessage(message: Message) {
                        resultBuilder.append(message.toString())
                    }
                    
                    override fun onDone() {
                        latch.countDown()
                    }
                    
                    override fun onError(throwable: Throwable) {
                        Log.e(TAG, "Inference callback error", throwable)
                        errorMessage = throwable.message
                        latch.countDown()
                    }
                }
            )
            
            // Wait for completion (90s internal timeout)
            val completed = latch.await(90, TimeUnit.SECONDS)
            
            if (!completed) {
                Log.w(TAG, "Inference timed out after 90s, cancelling...")
                try { conv.cancelProcess() } catch (_: Exception) {}
                try { conv.close() } catch (_: Exception) {}
                conversation = null
                return@withContext null
            }
            
            try { conv.close() } catch (_: Exception) {}
            conversation = null
            
            if (errorMessage != null) {
                Log.e(TAG, "Inference returned error: $errorMessage")
                return@withContext null
            }
            
            val text = resultBuilder.toString()
            Log.i(TAG, "Raw response (${text.length} chars): ${text.take(500)}")
            
            // Clean up control tokens
            val cleaned = text
                .replace(Regex("<\\|?turn\\|?>|<turn\\|>"), "")
                .replace(Regex("<\\|?model\\|?>"), "")
                .replace(Regex("<\\|?user\\|?>"), "")
                .replace(Regex("</?eos>"), "")
                .trim()
            
            Log.i(TAG, "Cleaned response (${cleaned.length} chars): ${cleaned.take(300)}")
            cleaned
        } catch (e: Exception) {
            Log.e(TAG, "Generation failed: ${e.message}", e)
            try { conversation?.close() } catch (_: Exception) {}
            conversation = null
            null
        }
    }

    /**
     * Generate content with coroutine timeout wrapper.
     */
    suspend fun generateContentWithTimeout(
        prompt: String,
        systemInstruction: String? = null,
        imageBytes: ByteArray? = null,
        audioBytes: ByteArray? = null,
        timeoutMs: Long = 120000
    ): String? {
        return try {
            withTimeout(timeoutMs) {
                generateContent(prompt, systemInstruction, imageBytes, audioBytes)
            }
        } catch (e: TimeoutCancellationException) {
            Log.w(TAG, "Generation timed out after ${timeoutMs}ms")
            try { conversation?.cancelProcess() } catch (_: Exception) {}
            try { conversation?.close() } catch (_: Exception) {}
            conversation = null
            null
        }
    }
}
