/// Structured voice commands parsed from speech input.
sealed class VoiceCommand {
  final String exerciseName;
  const VoiceCommand({required this.exerciseName});
}

/// "add bicep curl" → add exercise with default 3 empty sets
class AddExerciseCommand extends VoiceCommand {
  const AddExerciseCommand({required super.exerciseName});

  @override
  String toString() => 'Add $exerciseName (3 sets)';
}

/// "3 sets of bench press in 10kg" or "3 sets of bench press 80kg 8 reps"
class AddSetsCommand extends VoiceCommand {
  final int setCount;
  final double? weightKg;
  final int? reps;

  const AddSetsCommand({
    required super.exerciseName,
    required this.setCount,
    this.weightKg,
    this.reps,
  });

  @override
  String toString() {
    final parts = <String>['$setCount sets of $exerciseName'];
    if (weightKg != null) parts.add('${weightKg!.toStringAsFixed(weightKg! == weightKg!.roundToDouble() ? 0 : 1)}kg');
    if (reps != null) parts.add('$reps reps');
    return parts.join(' · ');
  }
}

/// "barbell curls in 10kg" or "bench press 80kg 8 reps"
/// Updates the latest incomplete set, or adds a new one.
class UpdateSetCommand extends VoiceCommand {
  final double weightKg;
  final int? reps;
  final bool completed;

  const UpdateSetCommand({
    required super.exerciseName,
    required this.weightKg,
    this.reps,
    this.completed = false,
  });

  @override
  String toString() {
    final w = '${weightKg.toStringAsFixed(weightKg == weightKg.roundToDouble() ? 0 : 1)}kg';
    return reps != null
        ? '$exerciseName · $w × $reps reps'
        : '$exerciseName · $w';
  }
}

/// "remove bench press" / "delete the last exercise"
class RemoveExerciseCommand extends VoiceCommand {
  const RemoveExerciseCommand({required super.exerciseName});

  @override
  String toString() => 'Remove $exerciseName';
}

/// "add a set to bench press" / "add 3 sets to curls"
class AddSetToExerciseCommand extends VoiceCommand {
  final int setCount;
  final double? weightKg;
  final int? reps;

  const AddSetToExerciseCommand({
    required super.exerciseName,
    this.setCount = 1,
    this.weightKg,
    this.reps,
  });

  @override
  String toString() {
    final parts = <String>['Add $setCount set${setCount > 1 ? 's' : ''} to $exerciseName'];
    if (weightKg != null) parts.add('${weightKg!.toStringAsFixed(weightKg! == weightKg!.roundToDouble() ? 0 : 1)}kg');
    if (reps != null) parts.add('$reps reps');
    return parts.join(' · ');
  }
}

/// "set 2 of bench press 90kg 6 reps"
class UpdateSpecificSetCommand extends VoiceCommand {
  final int setIndex; // 1-based
  final double weightKg;
  final int? reps;
  final bool completed;

  const UpdateSpecificSetCommand({
    required super.exerciseName,
    required this.setIndex,
    required this.weightKg,
    this.reps,
    this.completed = false,
  });

  @override
  String toString() {
    final w = '${weightKg.toStringAsFixed(weightKg == weightKg.roundToDouble() ? 0 : 1)}kg';
    return reps != null
        ? 'Set $setIndex of $exerciseName · $w × $reps reps'
        : 'Set $setIndex of $exerciseName · $w';
  }
}

/// "complete bench press" / "mark all sets done"
class CompleteExerciseCommand extends VoiceCommand {
  const CompleteExerciseCommand({required super.exerciseName});

  @override
  String toString() => 'Complete all $exerciseName sets';
}

/// Parsed result wrapping a command + the resolved exercise info.
class ParsedVoiceAction {
  final VoiceCommand command;
  final String? resolvedExerciseId;
  final String resolvedExerciseName;
  final String displayText;

  const ParsedVoiceAction({
    required this.command,
    this.resolvedExerciseId,
    required this.resolvedExerciseName,
    required this.displayText,
  });
}
