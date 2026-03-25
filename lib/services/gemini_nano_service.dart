import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/voice_command.dart';

/// Wrapper for on-device Gemini Nano inference via platform channel.
/// Only works on devices with AICore + Gemini Nano (Pixel 9+).
/// Falls back gracefully — isSupported will be false on unsupported devices.
class GeminiNanoService {
  static const _channel = MethodChannel('com.gymtrack.gemini_nano');
  bool _initialized = false;
  bool _supported = false;

  bool get isSupported => _supported;
  bool get isReady => _supported && _initialized;

  /// Check device compatibility and initialize if supported.
  Future<bool> initialize() async {
    try {
      _supported = await _channel.invokeMethod<bool>('isSupported') ?? false;
      if (!_supported) {
        print('GeminiNano: Device not supported');
        return false;
      }
      final ok = await _channel.invokeMethod<bool>('initialize') ?? false;
      _initialized = ok;
      print('GeminiNano: ${ok ? "Initialized" : "Init failed"}');
      return ok;
    } on MissingPluginException {
      // Platform channel not implemented — expected on most devices
      _supported = false;
      _initialized = false;
      return false;
    } catch (e) {
      print('GeminiNano: Init error: $e');
      _supported = false;
      _initialized = false;
      return false;
    }
  }

  /// Parse a voice transcript using Gemini Nano.
  /// Returns a parsed Map or null if unavailable/fails.
  Future<Map<String, dynamic>?> parseCommand(
    String transcript,
    List<String> exerciseContext,
  ) async {
    if (!isReady) return null;

    final contextStr = exerciseContext.isEmpty
        ? 'No exercises in workout yet.'
        : 'Current exercises: ${exerciseContext.join(", ")}';

    final prompt = '''You are a workout voice command parser. Parse the user's speech into a JSON action.

$contextStr

User said: "$transcript"

Return ONLY valid JSON (no markdown, no explanation) in one of these formats:

{"action":"add_exercise","exercise":"exercise name"}
{"action":"add_sets","exercise":"exercise name","sets":3,"weight":80,"reps":8}
{"action":"update_set","exercise":"exercise name","weight":80,"reps":8}
{"action":"update_specific_set","exercise":"exercise name","set_index":2,"weight":80,"reps":8}
{"action":"add_set_to","exercise":"exercise name","sets":1,"weight":80,"reps":8}
{"action":"remove_exercise","exercise":"exercise name"}
{"action":"complete_exercise","exercise":"exercise name"}

Rules:
- Match exercise names to the current workout context when possible
- If weight/reps not mentioned, omit those fields
- "set_index" is 1-based
- For "remove" or "delete", use action "remove_exercise"
- For "complete" or "mark done", use action "complete_exercise"
- For "add a set to" or "one more set", use action "add_set_to"
- For "set 2 of bench press 90kg", use "update_specific_set"
- Return ONLY the JSON object, nothing else''';

    try {
      final result = await _channel.invokeMethod<String>(
        'generateContent',
        {'prompt': prompt},
      );
      if (result == null) return null;

      final jsonStr = _extractJson(result.trim());
      if (jsonStr == null) return null;

      final parsed = json.decode(jsonStr) as Map<String, dynamic>;
      if (!parsed.containsKey('action') || !parsed.containsKey('exercise')) {
        return null;
      }
      return parsed;
    } on MissingPluginException {
      return null;
    } catch (e) {
      print('GeminiNano: Parse error: $e');
      return null;
    }
  }

  /// Convert a Gemini Nano JSON result into a VoiceCommand.
  VoiceCommand? jsonToCommand(Map<String, dynamic> json) {
    final action = json['action'] as String?;
    final exercise = json['exercise'] as String? ?? '';
    if (action == null || exercise.isEmpty) return null;

    switch (action) {
      case 'add_exercise':
        return AddExerciseCommand(exerciseName: exercise);
      case 'add_sets':
        return AddSetsCommand(
          exerciseName: exercise,
          setCount: (json['sets'] as num?)?.toInt() ?? 3,
          weightKg: (json['weight'] as num?)?.toDouble(),
          reps: (json['reps'] as num?)?.toInt(),
        );
      case 'update_set':
        final weight = (json['weight'] as num?)?.toDouble();
        if (weight == null) return null;
        return UpdateSetCommand(
          exerciseName: exercise,
          weightKg: weight,
          reps: (json['reps'] as num?)?.toInt(),
        );
      case 'update_specific_set':
        final weight = (json['weight'] as num?)?.toDouble();
        final setIdx = (json['set_index'] as num?)?.toInt();
        if (weight == null || setIdx == null) return null;
        return UpdateSpecificSetCommand(
          exerciseName: exercise,
          setIndex: setIdx,
          weightKg: weight,
          reps: (json['reps'] as num?)?.toInt(),
        );
      case 'add_set_to':
        return AddSetToExerciseCommand(
          exerciseName: exercise,
          setCount: (json['sets'] as num?)?.toInt() ?? 1,
          weightKg: (json['weight'] as num?)?.toDouble(),
          reps: (json['reps'] as num?)?.toInt(),
        );
      case 'remove_exercise':
        return RemoveExerciseCommand(exerciseName: exercise);
      case 'complete_exercise':
        return CompleteExerciseCommand(exerciseName: exercise);
      default:
        return null;
    }
  }

  String? _extractJson(String text) {
    if (text.startsWith('{')) return text;
    final codeBlock = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true)
        .firstMatch(text);
    if (codeBlock != null) return codeBlock.group(1);
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) return text.substring(start, end + 1);
    return null;
  }

  void dispose() {
    _initialized = false;
  }
}
