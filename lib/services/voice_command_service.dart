import 'dart:async';
import 'package:flutter/services.dart';
import '../data/database/app_database.dart';
import '../models/voice_command.dart';
import 'gemini_nano_service.dart';

/// Parses raw speech text into structured [VoiceCommand]s and fuzzy-matches
/// exercise names against the database.
/// Uses native Android ACTION_RECOGNIZE_SPEECH for voice input and
/// Gemini Nano on supported devices for smarter parsing.
class VoiceCommandService {
  static const _speechChannel = MethodChannel('com.gymtrack.speech');
  final GeminiNanoService _gemini = GeminiNanoService();
  bool _geminiInitialized = false;

  bool get isSmartMode => _gemini.isReady;

  /// Initialize Gemini Nano (non-blocking, OK to fail).
  Future<void> initialize() async {
    if (_geminiInitialized) return;
    try {
      await _gemini.initialize();
    } catch (_) {
      // Fallback to regex — no problem
    }
    _geminiInitialized = true;
  }

  /// Launch Android's native speech recognition dialog.
  /// Returns the recognized text, or null if cancelled.
  Future<String?> recognizeSpeech({String prompt = 'Say a workout command'}) async {
    try {
      final result = await _speechChannel.invokeMethod<String>('recognize', {
        'prompt': prompt,
      });
      return result;
    } on PlatformException {
      return null;
    }
  }

  void dispose() {
    _gemini.dispose();
  }

  // ─── Smart Command Parsing (Gemini Nano) ─────────────────────────────

  /// Parse using Gemini Nano with workout context. Returns null if not
  /// supported or parsing fails.
  Future<VoiceCommand?> parseCommandSmart(
    String raw,
    List<String> exerciseContext,
  ) async {
    if (!_gemini.isReady) return null;

    final json = await _gemini.parseCommand(raw, exerciseContext);
    if (json == null) return null;

    return _gemini.jsonToCommand(json);
  }

  // ─── Regex Command Parsing ───────────────────────────────────────────

  // Ordinal word → number mapping
  static final _ordinals = <String, int>{
    'first': 1, '1st': 1,
    'second': 2, '2nd': 2,
    'third': 3, '3rd': 3,
    'fourth': 4, '4th': 4,
    'fifth': 5, '5th': 5,
    'sixth': 6, '6th': 6,
    'seventh': 7, '7th': 7,
    'eighth': 8, '8th': 8,
    'ninth': 9, '9th': 9,
    'tenth': 10, '10th': 10,
  };

  // Number word → number mapping
  static final _numberWords = <String, int>{
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
  };

  /// Normalize text: lowercase, replace ordinals/number words, strip filler.
  String _normalize(String raw) {
    var text = raw.toLowerCase().trim();

    // Strip common filler words/phrases
    text = text
        .replaceAll(RegExp(r"\b(please|can you|could you|i want to|i want|i need to|i need|let me|let's|go ahead and|just)\b"), '')
        .replaceAll(RegExp(r'\b(the|a|an|my|for|on|this|that|it|to be)\b'), ' ');

    // Replace ordinal words with "set N" pattern
    for (final entry in _ordinals.entries) {
      text = text.replaceAll(
        RegExp('\\b${entry.key}\\s+set\\b'),
        'set ${entry.value}',
      );
      // Also handle "second set" → "set 2"
      text = text.replaceAll(
        RegExp('\\b${entry.key}\\b(?=.*(?:set|include|of))'),
        'set ${entry.value}',
      );
    }

    // Replace number words with digits
    for (final entry in _numberWords.entries) {
      text = text.replaceAll(RegExp('\\b${entry.key}\\b'), '${entry.value}');
    }

    // Normalize "include" → "set ... of" when pattern is "set N include exercise Xkg"
    text = text.replaceAll(RegExp(r'\binclude\b'), 'of');

    // Clean up multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Parse raw speech text into a [VoiceCommand] using regex patterns.
  VoiceCommand? parseCommand(String raw) {
    final text = _normalize(raw);
    if (text.isEmpty) return null;

    // ── Remove / Delete ──────────────────────────────────────────────
    final mRemove = RegExp(
      r'(?:remove|delete|drop|take out|get rid of)\s+(.+?)(?:\s+from\s+.+)?$',
    ).firstMatch(text);
    if (mRemove != null) {
      return RemoveExerciseCommand(exerciseName: _cleanName(mRemove.group(1)!));
    }

    // ── Complete / Mark done ─────────────────────────────────────────
    final mComplete = RegExp(
      r'(?:complete|finish|mark|done with)\s+(.+?)(?:\s+(?:as\s+)?done)?$',
    ).firstMatch(text);
    if (mComplete != null && !RegExp(r'\d+\s*(?:kg|set|rep)', caseSensitive: false).hasMatch(text)) {
      return CompleteExerciseCommand(exerciseName: _cleanName(mComplete.group(1)!));
    }

    // ── Set N of [exercise] Xkg Y reps ───────────────────────────────
    final mSpecific = RegExp(
      r'set\s+(\d+)\s+(?:of\s+)?(.+?)\s+(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?)\s+(\d+)\s*(?:reps?|repetitions?|times?)',
    ).firstMatch(text);
    if (mSpecific != null) {
      return UpdateSpecificSetCommand(
        exerciseName: _cleanName(mSpecific.group(2)!),
        setIndex: int.parse(mSpecific.group(1)!),
        weightKg: double.parse(mSpecific.group(3)!),
        reps: int.parse(mSpecific.group(4)!),
      );
    }

    // ── Set N of [exercise] Xkg (no reps) ────────────────────────────
    final mSpecific2 = RegExp(
      r'set\s+(\d+)\s+(?:of\s+)?(.+?)\s+(?:in\s+|at\s+|with\s+)?(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?)',
    ).firstMatch(text);
    if (mSpecific2 != null) {
      return UpdateSpecificSetCommand(
        exerciseName: _cleanName(mSpecific2.group(2)!),
        setIndex: int.parse(mSpecific2.group(1)!),
        weightKg: double.parse(mSpecific2.group(3)!),
      );
    }

    // ── Set N of [exercise] Y reps (no weight) ───────────────────────
    final mSpecific3 = RegExp(
      r'set\s+(\d+)\s+(?:of\s+)?(.+?)\s+(\d+)\s*(?:reps?|repetitions?|times?)',
    ).firstMatch(text);
    if (mSpecific3 != null) {
      return UpdateSpecificSetCommand(
        exerciseName: _cleanName(mSpecific3.group(2)!),
        setIndex: int.parse(mSpecific3.group(1)!),
        weightKg: 0,
        reps: int.parse(mSpecific3.group(3)!),
      );
    }

    // ── Add N sets TO existing exercise ──────────────────────────────
    final mAddTo = RegExp(
      r'add\s+(\d+)\s*sets?\s+to\s+(.+)',
    ).firstMatch(text);
    if (mAddTo != null) {
      return AddSetToExerciseCommand(
        exerciseName: _cleanName(mAddTo.group(2)!),
        setCount: int.parse(mAddTo.group(1)!),
      );
    }

    // ── "one more set of [exercise]" / "add a set to [exercise]" ─────
    final mOneMore = RegExp(
      r'(?:1\s+more\s+set\s+(?:of|to)\s+|add\s+(?:1\s+)?set\s+to\s+)(.+)',
    ).firstMatch(text);
    if (mOneMore != null) {
      return AddSetToExerciseCommand(
        exerciseName: _cleanName(mOneMore.group(1)!),
        setCount: 1,
      );
    }

    // ── N sets of [exercise] Xkg Y reps ──────────────────────────────
    final m1 = RegExp(
      r'(\d+)\s*sets?\s*(?:of\s+)?(.+?)\s+(?:in\s+|at\s+|with\s+)?(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?)\s+(\d+)\s*(?:reps?|repetitions?|times?)',
    ).firstMatch(text);
    if (m1 != null) {
      return AddSetsCommand(
        exerciseName: _cleanName(m1.group(2)!),
        setCount: int.parse(m1.group(1)!),
        weightKg: double.parse(m1.group(3)!),
        reps: int.parse(m1.group(4)!),
      );
    }

    // ── N sets of [exercise] in/at Xkg ───────────────────────────────
    final m2 = RegExp(
      r'(\d+)\s*sets?\s*(?:of\s+)?(.+?)\s+(?:in|at|with)\s+(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?)',
    ).firstMatch(text);
    if (m2 != null) {
      return AddSetsCommand(
        exerciseName: _cleanName(m2.group(2)!),
        setCount: int.parse(m2.group(1)!),
        weightKg: double.parse(m2.group(3)!),
      );
    }

    // ── N sets of [exercise] Xkg (without in/at) ─────────────────────
    final m2c = RegExp(
      r'(\d+)\s*sets?\s*(?:of\s+)?(.+?)\s+(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?)',
    ).firstMatch(text);
    if (m2c != null) {
      return AddSetsCommand(
        exerciseName: _cleanName(m2c.group(2)!),
        setCount: int.parse(m2c.group(1)!),
        weightKg: double.parse(m2c.group(3)!),
      );
    }

    // ── N sets of [exercise] (no weight) ─────────────────────────────
    final m2b = RegExp(
      r'(\d+)\s*sets?\s*(?:of\s+)?(.+)',
    ).firstMatch(text);
    if (m2b != null) {
      final name = _cleanName(m2b.group(2)!);
      if (name.isNotEmpty) {
        return AddSetsCommand(
          exerciseName: name,
          setCount: int.parse(m2b.group(1)!),
        );
      }
    }

    // ── [exercise] Xkg Y reps ────────────────────────────────────────
    final m3 = RegExp(
      r'(.+?)\s+(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?)\s+(\d+)\s*(?:reps?|repetitions?|times?)',
    ).firstMatch(text);
    if (m3 != null) {
      return UpdateSetCommand(
        exerciseName: _cleanName(m3.group(1)!),
        weightKg: double.parse(m3.group(2)!),
        reps: int.parse(m3.group(3)!),
      );
    }

    // ── [exercise] in/at/with Xkg ────────────────────────────────────
    final m4 = RegExp(
      r'(.+?)\s+(?:in|at|with)\s+(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?)',
    ).firstMatch(text);
    if (m4 != null) {
      return UpdateSetCommand(
        exerciseName: _cleanName(m4.group(1)!),
        weightKg: double.parse(m4.group(2)!),
      );
    }

    // ── [exercise] Xkg (no preposition) ──────────────────────────────
    final m4b = RegExp(
      r'(.+?)\s+(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?)$',
    ).firstMatch(text);
    if (m4b != null) {
      final name = _cleanName(m4b.group(1)!);
      if (name.isNotEmpty && !RegExp(r'^\d+$').hasMatch(name)) {
        return UpdateSetCommand(
          exerciseName: name,
          weightKg: double.parse(m4b.group(2)!),
        );
      }
    }

    // ── "add [exercise]" ─────────────────────────────────────────────
    final m5 = RegExp(r'add\s+(.+)').firstMatch(text);
    if (m5 != null) {
      return AddExerciseCommand(exerciseName: _cleanName(m5.group(1)!));
    }

    // Fallback: treat entire text as exercise name → add
    return AddExerciseCommand(exerciseName: _cleanName(text));
  }

  String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim();
  }

  // ─── Fuzzy Exercise Matching ──────────────────────────────────────────

  /// Find the best matching exercise from a list.
  ExerciseData? findBestMatch(String query, List<ExerciseData> exercises) {
    if (exercises.isEmpty || query.isEmpty) return null;

    final q = query.toLowerCase().trim();
    ExerciseData? best;
    double bestScore = 0;

    for (final ex in exercises) {
      final name = ex.name.toLowerCase();

      // Exact match
      if (name == q) return ex;

      // Substring match (high confidence)
      if (name.contains(q) || q.contains(name)) {
        final score = q.length / name.length;
        if (score > bestScore) {
          bestScore = score.clamp(0.0, 1.0);
          best = ex;
        }
        continue;
      }

      // Word overlap scoring
      final qWords = q.split(' ').where((w) => w.length > 1).toSet();
      final nWords = name.split(' ').where((w) => w.length > 1).toSet();
      if (qWords.isEmpty || nWords.isEmpty) continue;

      final overlap = qWords.intersection(nWords).length;
      final score = overlap / nWords.length;
      if (score > bestScore) {
        bestScore = score;
        best = ex;
      }
    }

    return bestScore >= 0.4 ? best : null;
  }

  /// Resolve a [VoiceCommand] into a [ParsedVoiceAction] by matching the
  /// exercise name against the provided exercise list.
  ParsedVoiceAction? resolve(VoiceCommand command, List<ExerciseData> exercises) {
    final match = findBestMatch(command.exerciseName, exercises);
    if (match == null) return null;

    String display;
    if (command is AddExerciseCommand) {
      display = 'Add ${match.name} (3 sets)';
    } else if (command is AddSetsCommand) {
      final parts = <String>['Add ${command.setCount} sets of ${match.name}'];
      if (command.weightKg != null) {
        parts.add('${command.weightKg!.toStringAsFixed(command.weightKg! == command.weightKg!.roundToDouble() ? 0 : 1)}kg');
      }
      if (command.reps != null) parts.add('${command.reps} reps');
      display = parts.join(' · ');
    } else if (command is UpdateSetCommand) {
      final w = command.weightKg.toStringAsFixed(
          command.weightKg == command.weightKg.roundToDouble() ? 0 : 1);
      display = command.reps != null
          ? 'Update ${match.name} · ${w}kg × ${command.reps} reps'
          : 'Update ${match.name} · ${w}kg';
    } else if (command is RemoveExerciseCommand) {
      display = 'Remove ${match.name} from workout';
    } else if (command is AddSetToExerciseCommand) {
      final parts = <String>['Add ${command.setCount} set${command.setCount > 1 ? 's' : ''} to ${match.name}'];
      if (command.weightKg != null) {
        parts.add('${command.weightKg!.toStringAsFixed(command.weightKg! == command.weightKg!.roundToDouble() ? 0 : 1)}kg');
      }
      if (command.reps != null) parts.add('${command.reps} reps');
      display = parts.join(' · ');
    } else if (command is UpdateSpecificSetCommand) {
      final w = command.weightKg.toStringAsFixed(
          command.weightKg == command.weightKg.roundToDouble() ? 0 : 1);
      display = command.reps != null
          ? 'Set ${command.setIndex} of ${match.name} · ${w}kg × ${command.reps} reps'
          : 'Set ${command.setIndex} of ${match.name} · ${w}kg';
    } else if (command is CompleteExerciseCommand) {
      display = 'Complete all ${match.name} sets';
    } else {
      display = command.toString();
    }

    return ParsedVoiceAction(
      command: command,
      resolvedExerciseId: match.id,
      resolvedExerciseName: match.name,
      displayText: display,
    );
  }
}
