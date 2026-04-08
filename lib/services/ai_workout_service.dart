import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/preset_pack.dart';
import '../models/enums.dart';
import 'gemma_model_service.dart';

class AiWorkoutService {
  final GemmaModelService _gemmaService;

  AiWorkoutService(this._gemmaService);

  static const _systemInstruction =
      'You are a fitness coach. Reply ONLY with a JSON array, no text. '
      'Format: [{"name":"Day","notes":"short","exercises":[{"name":"Exercise","sets":3,"reps":10}]}] '
      'Use common exercise names. Max 4 exercises per routine, 3 sets each. Be concise.';

  /// Generate workout routines from a user prompt.
  /// Returns a list of PresetRoutine objects ready to add via PresetPackService.
  Future<List<PresetRoutine>> generateWorkout(String userPrompt) async {
    final prompt = userPrompt.trim();

    final response = await _gemmaService.infer(
      prompt,
      systemInstruction: _systemInstruction,
    );

    return _parseResponse(response);
  }

  /// Generate workout routines with streaming token display.
  /// [onToken] is called with each token as it arrives.
  /// [onStatus] is called with status messages (e.g. "Loading model...", "Thinking...").
  Future<List<PresetRoutine>> generateWorkoutStreaming(
    String userPrompt, {
    void Function(String token)? onToken,
    void Function(String status)? onStatus,
  }) async {
    final prompt = userPrompt.trim();

    final (:stream, :result) = _gemmaService.inferStream(
      prompt,
      systemInstruction: _systemInstruction,
    );

    // Listen to the stream for tokens
    final subscription = stream.listen((event) {
      final type = event['type'] as String?;
      if (type == 'token') {
        onToken?.call(event['data'] as String? ?? '');
      } else if (type == 'status') {
        onStatus?.call(event['message'] as String? ?? '');
      }
    });

    try {
      final response = await result;
      await subscription.cancel();
      return _parseResponse(response);
    } catch (e) {
      await subscription.cancel();
      rethrow;
    }
  }

  List<PresetRoutine> _parseResponse(String response) {
    String jsonStr = response.trim();

    // Find JSON array start
    final arrayStart = jsonStr.indexOf('[');
    if (arrayStart == -1) {
      throw FormatException('AI response did not contain a workout plan. Please try again.');
    }
    jsonStr = jsonStr.substring(arrayStart);

    // Try to find complete array
    final arrayEnd = jsonStr.lastIndexOf(']');
    if (arrayEnd > 0) {
      jsonStr = jsonStr.substring(0, arrayEnd + 1);
    }

    // Try parsing as-is first
    List<dynamic>? routinesJson;
    try {
      routinesJson = jsonDecode(jsonStr) as List<dynamic>;
    } catch (_) {
      // JSON truncated — try to repair by closing open structures
      routinesJson = _repairAndParse(jsonStr);
    }

    if (routinesJson == null || routinesJson.isEmpty) {
      throw FormatException('Could not parse the AI response. Try a simpler prompt.');
    }

    return routinesJson.map((r) {
      final map = r as Map<String, dynamic>;
      final exercises = (map['exercises'] as List<dynamic>? ?? []).map((e) {
        final ex = e as Map<String, dynamic>;
        return PresetExercise(
          exerciseName: ex['name'] as String? ?? 'Unknown Exercise',
          sets: (ex['sets'] as num?)?.toInt() ?? 3,
          reps: (ex['reps'] as num?)?.toInt() ?? 10,
          durationSeconds: (ex['duration'] as num?)?.toInt(),
          trackingType: ex['duration'] != null ? TrackingType.duration : TrackingType.reps,
        );
      }).toList();

      return PresetRoutine(
        name: map['name'] as String? ?? 'Workout',
        notes: map['notes'] as String?,
        exercises: exercises,
      );
    }).toList();
  }

  /// Attempt to repair truncated JSON by extracting complete routine objects.
  List<dynamic>? _repairAndParse(String truncated) {
    // Strategy: find all complete top-level objects in the array
    // by matching balanced braces
    final results = <dynamic>[];
    int depth = 0;
    int objectStart = -1;

    // Skip the opening '['
    final start = truncated.indexOf('[');
    if (start == -1) return null;

    bool inString = false;
    bool escaped = false;

    for (int i = start + 1; i < truncated.length; i++) {
      final ch = truncated[i];

      if (escaped) {
        escaped = false;
        continue;
      }
      if (ch == '\\') {
        escaped = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (ch == '{') {
        if (depth == 0) objectStart = i;
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0 && objectStart != -1) {
          final objectStr = truncated.substring(objectStart, i + 1);
          try {
            final obj = jsonDecode(objectStr);
            // Only include if it has a name and exercises
            if (obj is Map && obj.containsKey('name') && obj.containsKey('exercises')) {
              results.add(obj);
            }
          } catch (_) {
            // Skip malformed objects
          }
          objectStart = -1;
        }
      }
    }

    return results.isEmpty ? null : results;
  }
}

final aiWorkoutServiceProvider = Provider<AiWorkoutService>((ref) {
  final gemmaService = ref.read(gemmaModelServiceProvider);
  return AiWorkoutService(gemmaService);
});
