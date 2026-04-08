import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../data/database/app_database.dart';
import '../models/voice_command.dart';
import 'gemma_model_service.dart';
import 'workout_tools_schema.dart';

class VoiceCommandService {
  final GemmaModelService _gemmaModelService;

  VoiceCommandService(this._gemmaModelService);

  Future<void> initialize() async {}

  void dispose() {}

  /// Always true — only AI mode is supported.
  bool get isSmartMode => true;

  /// Parse a voice command using the AI model.
  /// Audio bytes are sent directly to the model for speech understanding.
  Future<VoiceCommand?> parseCommandSmart(
    String raw,
    List<String> exerciseContext, {
    Uint8List? audioBytes,
  }) async {
    try {
      final prompt = _buildPrompt(raw, exerciseContext);
      // Don't pass tools separately — _buildPrompt already includes the full schema
      final jsonString = await _gemmaModelService.infer(
        prompt,
        audioBytes: audioBytes,
      );
      if (jsonString.isEmpty) return null;
      
      // print("Model response: $jsonString");
      
      // Extract JSON from the response (model may include extra text)
      final firstBrace = jsonString.indexOf('{');
      if (firstBrace == -1) {
        // print("No JSON found in response");
        return null;
      }
      // Find matching closing brace
      int depth = 0;
      int lastBrace = -1;
      for (int i = firstBrace; i < jsonString.length; i++) {
        if (jsonString[i] == '{') depth++;
        if (jsonString[i] == '}') {
          depth--;
          if (depth == 0) { lastBrace = i; break; }
        }
      }
      if (lastBrace == -1) {
        // print("No matching closing brace found");
        return null;
      }
      
      final jsonStr = jsonString.substring(firstBrace, lastBrace + 1);
      // print("Extracted JSON: $jsonStr");
      
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return _jsonToCommand(json);
    } on PlatformException catch (e) {
      print("Gemma platform error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Gemma inference error: $e");
      return null;
    }
  }

  String _buildPrompt(String raw, List<String> exerciseContext) {
    final systemInstructions = WorkoutToolsSchema.getSystemInstructions();
    final toolsSchema = WorkoutToolsSchema.getToolsSchema();
    final workoutContext = WorkoutToolsSchema.buildWorkoutContext(exerciseContext);
    
    final userCommand = raw.isEmpty
        ? 'Listen to the audio and determine the workout command.'
        : '"$raw"';
    
    return '''$systemInstructions
$toolsSchema$workoutContext

User: $userCommand
JSON:'''.trim();
  }

  VoiceCommand? _jsonToCommand(Map<String, dynamic> json) {
    final tool = json['tool'] as String?;
    final parameters = json['parameters'] as Map<String, dynamic>?;
    
    if (tool == null || parameters == null) return null;
    return _toolCallToCommand(tool, parameters);
  }
  
  /// Convert tool call format to VoiceCommand
  VoiceCommand? _toolCallToCommand(String tool, Map<String, dynamic> parameters) {
    final exerciseName = parameters['exercise_name'] as String?;
    if (exerciseName == null) return null;
    
    switch (tool) {
      case 'add_exercise':
        return AddExerciseCommand(exerciseName: exerciseName);
        
      case 'add_sets':
        final sets = parameters['sets'] as int? ?? 1;
        final weight = (parameters['weight'] as num?)?.toDouble();
        final reps = parameters['reps'] as int?;
        return AddSetsCommand(
          exerciseName: exerciseName,
          weightKg: weight,
          reps: reps,
          setCount: sets,
        );
        
      case 'update_set':
        final weight = (parameters['weight'] as num?)?.toDouble() ?? 0.0;
        final reps = parameters['reps'] as int?;
        final completed = parameters['completed'] as bool? ?? false;
        return UpdateSetCommand(
          exerciseName: exerciseName,
          weightKg: weight,
          reps: reps,
          completed: completed,
        );
        
      case 'add_set_to':
        final sets = parameters['sets'] as int? ?? 1;
        return AddSetToExerciseCommand(
          exerciseName: exerciseName,
          setCount: sets,
        );
        
      case 'update_specific_set':
        final setNumber = parameters['set_number'] as int?;
        if (setNumber == null) return null;
        final weight = (parameters['weight'] as num?)?.toDouble() ?? 0.0;
        final reps = parameters['reps'] as int?;
        final completed = parameters['completed'] as bool? ?? false;
        return UpdateSpecificSetCommand(
          exerciseName: exerciseName,
          setIndex: setNumber,
          weightKg: weight,
          reps: reps,
          completed: completed,
        );
        
      case 'remove_exercise':
        return RemoveExerciseCommand(exerciseName: exerciseName);
        
      case 'complete_exercise':
        return CompleteExerciseCommand(exerciseName: exerciseName);
        
      default:
        return null;
    }
  }

  ExerciseData? findBestMatch(String query, List<ExerciseData> exercises) {
    if (exercises.isEmpty || query.isEmpty) return null;
    final q = query.toLowerCase().trim();
    ExerciseData? best;
    double bestScore = 0;
    for (final ex in exercises) {
      final name = ex.name.toLowerCase();
      if (name == q) return ex;
      if (name.contains(q)) {
        final score = q.length / name.length;
        if (score > bestScore) {
          bestScore = score;
          best = ex;
        }
      }
    }
    return bestScore > 0.4 ? best : null;
  }

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
      display = 'Remove ${match.name}';
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
