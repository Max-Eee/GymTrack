package com.gymtrack.gym_track

import android.content.Context
import android.util.Log
import com.google.ai.edge.aicore.GenerativeModel
import com.google.ai.edge.aicore.generationConfig

class GeminiNanoHelper {
    private var model: GenerativeModel? = null

    suspend fun initialize(context: Context): Boolean {
        return try {
            val config = generationConfig {
                this.context = context
                temperature = 0.2f
                topK = 16
                maxOutputTokens = 256
            }
            model = GenerativeModel(generationConfig = config)
            true
        } catch (e: Exception) {
            Log.e("GeminiNano", "Init failed: ${e.message}", e)
            false
        }
    }

    suspend fun generateContent(prompt: String): String? {
        return try {
            val response = model?.generateContent(prompt)
            response?.text
        } catch (e: Exception) {
            Log.e("GeminiNano", "Generate failed: ${e.message}", e)
            null
        }
    }
}
