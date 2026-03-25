package com.gymtrack.gym_track

import android.app.Activity
import android.content.Intent
import android.speech.RecognizerIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val GEMINI_CHANNEL = "com.gymtrack.gemini_nano"
    private val SPEECH_CHANNEL = "com.gymtrack.speech"
    private val SPEECH_REQUEST_CODE = 9001
    private var geminiHelper: GeminiNanoHelper? = null
    private var pendingSpeechResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Gemini Nano channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GEMINI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(checkAiCoreAvailable())
                }
                "initialize" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            geminiHelper = GeminiNanoHelper()
                            val success = geminiHelper!!.initialize(this@MainActivity)
                            withContext(Dispatchers.Main) {
                                result.success(success)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.success(false)
                            }
                        }
                    }
                }
                "generateContent" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt == null) {
                        result.error("INVALID_ARG", "Missing prompt", null)
                        return@setMethodCallHandler
                    }
                    val helper = geminiHelper
                    if (helper == null) {
                        result.error("NOT_INITIALIZED", "Gemini Nano not initialized", null)
                        return@setMethodCallHandler
                    }
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val response = helper.generateContent(prompt)
                            withContext(Dispatchers.Main) {
                                result.success(response)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("GENERATION_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Native speech recognition channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "recognize" -> {
                    pendingSpeechResult = result
                    val prompt = call.argument<String>("prompt") ?: "Say a command"
                    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                        putExtra(RecognizerIntent.EXTRA_PROMPT, prompt)
                        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                    }
                    try {
                        startActivityForResult(intent, SPEECH_REQUEST_CODE)
                    } catch (e: Exception) {
                        pendingSpeechResult = null
                        result.error("NO_RECOGNIZER", "Speech recognizer not available", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SPEECH_REQUEST_CODE) {
            val pending = pendingSpeechResult
            pendingSpeechResult = null
            if (resultCode == Activity.RESULT_OK && data != null) {
                val results = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                pending?.success(results?.firstOrNull() ?: "")
            } else {
                pending?.success(null)
            }
        }
    }

    private fun checkAiCoreAvailable(): Boolean {
        return try {
            Class.forName("com.google.ai.edge.aicore.GenerativeModel")
            true
        } catch (e: Exception) {
            false
        }
    }
}
