import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../../models/voice_command.dart';
import '../../../data/database/app_database.dart';
import '../../../services/voice_command_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/workout_providers.dart';
import '../../widgets/voice_confirmation_card.dart';

// ---------------------------------------------------------------------------
// In-memory models for tracking workout state
// ---------------------------------------------------------------------------

class SetEntry {
  String id;
  double? weight;
  int? reps;
  bool isCompleted;
  bool isWarmUp;

  SetEntry({
    required this.id,
    this.weight,
    this.reps,
    this.isCompleted = false,
    this.isWarmUp = false,
  });
}

class ExerciseEntry {
  final String exerciseId;
  final String exerciseName;
  String? workoutLogExerciseId;
  List<SetEntry> sets;
  TrackingType trackingType;
  int? plannedReps;

  ExerciseEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.trackingType,
    this.workoutLogExerciseId,
    this.plannedReps,
  });
}

// ---------------------------------------------------------------------------
// Active Workout Screen
// ---------------------------------------------------------------------------

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String routineId;
  final String routineName;

  const ActiveWorkoutScreen({
    super.key,
    required this.routineId,
    required this.routineName,
  });

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  // Elapsed timer
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Rest timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _restTotalSeconds = 0;
  bool _showRestTimer = false;

  // Workout state
  String? _workoutLogId;
  List<ExerciseEntry> _exercises = [];
  bool _isInitialised = false;
  bool _isSaving = false;

  // Text editing controllers keyed by "${exerciseIndex}_${setIndex}_weight/reps"
  final Map<String, TextEditingController> _controllers = {};

  static const _uuid = Uuid();

  // Voice assistant state
  final VoiceCommandService _voiceService = VoiceCommandService();
  ParsedVoiceAction? _pendingAction;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _voiceService.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  // -------------------------------------------------------------------------
  // Format helpers
  // -------------------------------------------------------------------------

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  // -------------------------------------------------------------------------
  // Initialisation – create DB records
  // -------------------------------------------------------------------------

  Future<void> _initialiseWorkout(
      List<WorkoutPlanExerciseData> planExercises) async {
    if (_isInitialised) return;
    _isInitialised = true;

    final repo = ref.read(workoutRepositoryProvider);

    // Create the workout log
    final logId = _uuid.v4();
    await repo.insertWorkoutLog(
      WorkoutLogsCompanion.insert(
        id: logId,
        workoutPlanId: widget.routineId,
        date: DateTime.now(),
        duration: 0,
        inProgress: const drift.Value(true),
      ),
    );
    _workoutLogId = logId;

    // Resolve exercise names in parallel
    final exerciseNames = <String, String>{};
    for (final pe in planExercises) {
      final data = await ref.read(exerciseRepositoryProvider).getExercise(pe.exerciseId);
      exerciseNames[pe.exerciseId] = data?.name ?? 'Exercise';
    }

    // Create log exercises & build in-memory list
    final entries = <ExerciseEntry>[];
    for (final pe in planExercises) {
      final logExId = _uuid.v4();
      await repo.insertWorkoutLogExercise(
        WorkoutLogExercisesCompanion.insert(
          id: logExId,
          workoutLogId: logId,
          exerciseId: pe.exerciseId,
          trackingType: pe.trackingType,
        ),
      );

      final sets = List.generate(
        pe.sets,
        (_) => SetEntry(id: _uuid.v4()),
      );

      entries.add(ExerciseEntry(
        exerciseId: pe.exerciseId,
        exerciseName: exerciseNames[pe.exerciseId] ?? 'Exercise',
        sets: sets,
        trackingType: pe.trackingType,
        workoutLogExerciseId: logExId,
        plannedReps: pe.reps,
      ));
    }

    if (mounted) setState(() => _exercises = entries);
  }

  // -------------------------------------------------------------------------
  // Controller helpers
  // -------------------------------------------------------------------------

  TextEditingController _ctrl(String key, [String? initial]) {
    return _controllers.putIfAbsent(key, () {
      final c = TextEditingController(text: initial);
      return c;
    });
  }

  // -------------------------------------------------------------------------
  // Set actions
  // -------------------------------------------------------------------------

  Future<void> _toggleSetComplete(int exIdx, int setIdx) async {
    final exercise = _exercises[exIdx];
    final set = exercise.sets[setIdx];

    // Read values from controllers
    final wKey = '${exIdx}_${setIdx}_w';
    final rKey = '${exIdx}_${setIdx}_r';
    final weightText = _controllers[wKey]?.text ?? '';
    final repsText = _controllers[rKey]?.text ?? '';

    final weight = double.tryParse(weightText);
    final reps = int.tryParse(repsText);

    setState(() {
      set.isCompleted = !set.isCompleted;
      set.weight = weight;
      set.reps = reps;
    });

    // Persist to DB
    final repo = ref.read(workoutRepositoryProvider);
    if (set.isCompleted && exercise.workoutLogExerciseId != null) {
      await repo.insertSetLog(
        SetLogsCompanion.insert(
          id: set.id,
          workoutLogExerciseId: exercise.workoutLogExerciseId!,
          weight: drift.Value(weight),
          reps: drift.Value(reps),
          order: drift.Value(setIdx),
          isWarmUp: drift.Value(set.isWarmUp),
        ),
      );
      // Start rest timer automatically
      if (!_showRestTimer) _startRestTimer(60);
    } else {
      // Un-completing – delete the set log
      await repo.deleteSetLog(set.id);
    }
  }

  void _addSet(int exIdx) {
    setState(() {
      _exercises[exIdx].sets.add(SetEntry(id: _uuid.v4()));
    });
  }

  void _removeSet(int exIdx, int setIdx) async {
    final set = _exercises[exIdx].sets[setIdx];
    if (set.isCompleted && _exercises[exIdx].workoutLogExerciseId != null) {
      await ref.read(workoutRepositoryProvider).deleteSetLog(set.id);
    }
    _controllers.remove('${exIdx}_${setIdx}_w');
    _controllers.remove('${exIdx}_${setIdx}_r');
    setState(() {
      _exercises[exIdx].sets.removeAt(setIdx);
    });
  }

  void _confirmRemoveExercise(int exIdx) {
    // Prevent removing last exercise
    if (_exercises.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the last exercise from workout'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final exercise = _exercises[exIdx];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Exercise',
            style: TextStyle(color: AppColors.textPrimaryDark)),
        content: Text(
          'Remove "${exercise.exerciseName}" from this workout?',
          style: const TextStyle(color: AppColors.textSecondaryDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeExerciseFromWorkout(exIdx);
            },
            child: const Text('Remove',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _removeExerciseFromWorkout(int exIdx) {
    // Clean up controllers for this exercise's sets
    final exercise = _exercises[exIdx];
    for (var i = 0; i < exercise.sets.length; i++) {
      _controllers.remove('${exIdx}_${i}_w')?.dispose();
      _controllers.remove('${exIdx}_${i}_r')?.dispose();
    }

    setState(() {
      _exercises.removeAt(exIdx);
    });

    // Re-key controllers for exercises after the removed one
    final newControllers = <String, TextEditingController>{};
    for (final entry in _controllers.entries) {
      final parts = entry.key.split('_');
      if (parts.length == 3) {
        final oldExIdx = int.tryParse(parts[0]);
        if (oldExIdx != null && oldExIdx > exIdx) {
          newControllers['${oldExIdx - 1}_${parts[1]}_${parts[2]}'] =
              entry.value;
        } else {
          newControllers[entry.key] = entry.value;
        }
      } else {
        newControllers[entry.key] = entry.value;
      }
    }
    _controllers
      ..clear()
      ..addAll(newControllers);
  }

  bool _areAllSetsCompleted(int exIdx) {
    return _exercises[exIdx].sets.every((s) => s.isCompleted);
  }

  bool _allSetsHaveValues(int exIdx) {
    for (var i = 0; i < _exercises[exIdx].sets.length; i++) {
      final wKey = '${exIdx}_${i}_w';
      final rKey = '${exIdx}_${i}_r';
      final weight = double.tryParse(_controllers[wKey]?.text ?? '');
      final reps = int.tryParse(_controllers[rKey]?.text ?? '');
      if (weight == null || weight <= 0 || reps == null || reps <= 0) return false;
    }
    return _exercises[exIdx].sets.isNotEmpty;
  }

  Future<void> _toggleAllSets(int exIdx) async {
    final exercise = _exercises[exIdx];
    final allCompleted = _areAllSetsCompleted(exIdx);

    if (allCompleted) {
      for (var i = 0; i < exercise.sets.length; i++) {
        if (exercise.sets[i].isCompleted) {
          await _toggleSetComplete(exIdx, i);
        }
      }
    } else {
      for (var i = 0; i < exercise.sets.length; i++) {
        if (!exercise.sets[i].isCompleted) {
          final wKey = '${exIdx}_${i}_w';
          final rKey = '${exIdx}_${i}_r';
          final weight = double.tryParse(_controllers[wKey]?.text ?? '');
          final reps = int.tryParse(_controllers[rKey]?.text ?? '');
          if (weight != null && weight > 0 && reps != null && reps > 0) {
            await _toggleSetComplete(exIdx, i);
          }
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Rest timer
  // -------------------------------------------------------------------------

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restTotalSeconds = seconds;
      _restSecondsRemaining = seconds;
      _showRestTimer = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restSecondsRemaining <= 1) {
        _restTimer?.cancel();
        if (mounted) {
          setState(() => _showRestTimer = false);
          HapticFeedback.mediumImpact();
        }
      } else {
        if (mounted) setState(() => _restSecondsRemaining--);
      }
    });
  }

  void _dismissRestTimer() {
    _restTimer?.cancel();
    setState(() => _showRestTimer = false);
  }

  // -------------------------------------------------------------------------
  // Finish workout
  // -------------------------------------------------------------------------

  Future<void> _finishWorkout() async {
    if (_isSaving || _workoutLogId == null) return;
    setState(() => _isSaving = true);

    final repo = ref.read(workoutRepositoryProvider);

    // Save any un-saved completed sets (idempotent via primary key)
    for (var exIdx = 0; exIdx < _exercises.length; exIdx++) {
      final exercise = _exercises[exIdx];
      for (var setIdx = 0; setIdx < exercise.sets.length; setIdx++) {
        final set = exercise.sets[setIdx];
        if (!set.isCompleted) continue;
        // Re-read controllers in case user edited after completing
        final wKey = '${exIdx}_${setIdx}_w';
        final rKey = '${exIdx}_${setIdx}_r';
        set.weight = double.tryParse(_controllers[wKey]?.text ?? '');
        set.reps = int.tryParse(_controllers[rKey]?.text ?? '');
      }
    }

    // Fetch the log to get createdAt for the update
    final existingLog = await repo.getWorkoutLog(_workoutLogId!);
    if (existingLog != null) {
      final updated = WorkoutLogData(
        id: existingLog.id,
        workoutPlanId: existingLog.workoutPlanId,
        date: existingLog.date,
        duration: _elapsedSeconds,
        inProgress: false,
        createdAt: existingLog.createdAt,
        dateUpdated: DateTime.now(),
      );
      await repo.updateWorkoutLog(updated);
    }

    _timer?.cancel();
    _restTimer?.cancel();

    if (mounted) {
      setState(() => _isSaving = false);
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final completedSets = _exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.where((s) => s.isCompleted).length,
    );
    final totalVolume = _exercises.fold<double>(0.0, (sum, e) {
      return sum +
          e.sets
              .where((s) => s.isCompleted && s.weight != null && s.reps != null)
              .fold<double>(0, (v, s) => v + s.weight! * s.reps!);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.emoji_events_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            const Text('Workout Complete!',
                style: TextStyle(color: AppColors.textPrimaryDark)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statRow(Icons.timer_outlined, 'Duration',
                _formatDuration(_elapsedSeconds)),
            const SizedBox(height: 12),
            _statRow(Icons.fitness_center_rounded, 'Sets Completed',
                '$completedSets'),
            const SizedBox(height: 12),
            _statRow(Icons.trending_up_rounded, 'Total Volume',
                '${totalVolume.toStringAsFixed(0)} kg'),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusMedium),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).pop(); // screen
              },
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondaryDark, size: 20),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondaryDark, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Cancel / back
  // -------------------------------------------------------------------------

  Future<bool> _onWillPop() async {
    if (_workoutLogId == null) return true; // Not yet started, safe to pop

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        title: const Text('Cancel Workout?',
            style: TextStyle(color: AppColors.textPrimaryDark)),
        content: const Text(
          'Your progress will be lost. Are you sure you want to cancel?',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Going',
                style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Workout',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _timer?.cancel();
      _restTimer?.cancel();
      await ref.read(workoutRepositoryProvider).deleteWorkoutLog(_workoutLogId!);
      return true;
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Voice Assistant
  // -------------------------------------------------------------------------

  Future<void> _startVoiceListening() async {
    await _voiceService.initialize();

    // Launch native Android speech recognition dialog
    final text = await _voiceService.recognizeSpeech(
      prompt: 'Say a workout command',
    );

    if (text == null || text.trim().isEmpty) {
      // User cancelled or no speech detected
      return;
    }

    if (!mounted) return;
    await _processVoiceInput(text);
  }

  Future<void> _processVoiceInput(String text) async {

    VoiceCommand? command;

    // Try Gemini Nano first (smart mode)
    if (_voiceService.isSmartMode) {
      final exerciseContext =
          _exercises.map((e) => e.exerciseName).toList();
      command = await _voiceService.parseCommandSmart(text, exerciseContext);
    }

    // Fallback to regex
    command ??= _voiceService.parseCommand(text);

    if (command == null) {
      _showVoiceError('Could not understand: "$text"');
      return;
    }

    // For remove/complete commands, try matching against current workout exercises first
    final exercises = await ref.read(allExercisesProvider.future);
    final action = _voiceService.resolve(command, exercises);
    if (action == null) {
      _showVoiceError('Exercise not found: "${command.exerciseName}"');
      return;
    }

    setState(() => _pendingAction = action);
  }

  void _executeVoiceAction(ParsedVoiceAction action) {
    final cmd = action.command;
    final exId = action.resolvedExerciseId!;
    final exName = action.resolvedExerciseName;

    if (cmd is AddExerciseCommand) {
      _voiceAddExercise(exId, exName, 3, null, null);
    } else if (cmd is AddSetsCommand) {
      _voiceAddOrUpdateExercise(
        exId, exName, cmd.setCount, cmd.weightKg, cmd.reps,
      );
    } else if (cmd is UpdateSetCommand) {
      _voiceUpdateLatestSet(exId, exName, cmd.weightKg, cmd.reps);
    } else if (cmd is RemoveExerciseCommand) {
      _voiceRemoveExercise(exId);
    } else if (cmd is AddSetToExerciseCommand) {
      _voiceAddSetsToExisting(exId, exName, cmd.setCount, cmd.weightKg, cmd.reps);
    } else if (cmd is UpdateSpecificSetCommand) {
      _voiceUpdateSpecificSet(exId, cmd.setIndex, cmd.weightKg, cmd.reps);
    } else if (cmd is CompleteExerciseCommand) {
      _voiceCompleteExercise(exId);
    }

    setState(() => _pendingAction = null);
  }

  void _voiceAddExercise(
    String exId, String exName, int setCount, double? kg, int? reps,
  ) async {
    final repo = ref.read(workoutRepositoryProvider);
    final logExId = _uuid.v4();
    await repo.insertWorkoutLogExercise(
      WorkoutLogExercisesCompanion.insert(
        id: logExId,
        workoutLogId: _workoutLogId!,
        exerciseId: exId,
        trackingType: TrackingType.reps,
      ),
    );

    final sets = List.generate(setCount, (_) => SetEntry(id: _uuid.v4()));
    setState(() {
      _exercises.add(ExerciseEntry(
        exerciseId: exId,
        exerciseName: exName,
        sets: sets,
        trackingType: TrackingType.reps,
        workoutLogExerciseId: logExId,
      ));
    });

    // Pre-fill weight/reps if provided
    if (kg != null || reps != null) {
      final exIdx = _exercises.length - 1;
      for (var i = 0; i < setCount; i++) {
        if (kg != null) {
          _ctrl('${exIdx}_${i}_w').text = kg.toStringAsFixed(
              kg == kg.roundToDouble() ? 0 : 1);
        }
        if (reps != null) {
          _ctrl('${exIdx}_${i}_r').text = reps.toString();
        }
      }
    }
  }

  void _voiceAddOrUpdateExercise(
    String exId, String exName, int setCount, double? kg, int? reps,
  ) {
    // Check if exercise already in workout
    final existingIdx =
        _exercises.indexWhere((e) => e.exerciseId == exId);
    if (existingIdx >= 0) {
      // Add sets to existing exercise
      setState(() {
        for (var i = 0; i < setCount; i++) {
          _exercises[existingIdx].sets.add(SetEntry(id: _uuid.v4()));
        }
      });
      // Pre-fill the new sets
      final startSet = _exercises[existingIdx].sets.length - setCount;
      for (var i = 0; i < setCount; i++) {
        final setIdx = startSet + i;
        if (kg != null) {
          _ctrl('${existingIdx}_${setIdx}_w').text = kg.toStringAsFixed(
              kg == kg.roundToDouble() ? 0 : 1);
        }
        if (reps != null) {
          _ctrl('${existingIdx}_${setIdx}_r').text = reps.toString();
        }
      }
    } else {
      _voiceAddExercise(exId, exName, setCount, kg, reps);
    }
  }

  void _voiceUpdateLatestSet(
    String exId, String exName, double kg, int? reps,
  ) {
    final existingIdx =
        _exercises.indexWhere((e) => e.exerciseId == exId);

    if (existingIdx >= 0) {
      final exercise = _exercises[existingIdx];
      // Find latest incomplete set
      var targetSet = -1;
      for (var i = 0; i < exercise.sets.length; i++) {
        if (!exercise.sets[i].isCompleted) {
          targetSet = i;
          break;
        }
      }

      if (targetSet < 0) {
        // All sets completed — add a new one
        setState(() {
          exercise.sets.add(SetEntry(id: _uuid.v4()));
        });
        targetSet = exercise.sets.length - 1;
      }

      // Update the controllers
      _ctrl('${existingIdx}_${targetSet}_w').text = kg.toStringAsFixed(
          kg == kg.roundToDouble() ? 0 : 1);
      if (reps != null) {
        _ctrl('${existingIdx}_${targetSet}_r').text = reps.toString();
      }
      setState(() {});
    } else {
      // Exercise not in workout — add it with 1 set
      _voiceAddExercise(exId, exName, 1, kg, reps);
    }
  }

  void _voiceRemoveExercise(String exId) {
    final idx = _exercises.indexWhere((e) => e.exerciseId == exId);
    if (idx < 0) {
      _showVoiceError('Exercise not in current workout');
      return;
    }
    if (_exercises.length == 1) {
      _showVoiceError('Cannot remove the last exercise');
      return;
    }
    _removeExerciseFromWorkout(idx);
  }

  void _voiceAddSetsToExisting(
    String exId, String exName, int count, double? kg, int? reps,
  ) {
    final idx = _exercises.indexWhere((e) => e.exerciseId == exId);
    if (idx >= 0) {
      final startSet = _exercises[idx].sets.length;
      setState(() {
        for (var i = 0; i < count; i++) {
          _exercises[idx].sets.add(SetEntry(id: _uuid.v4()));
        }
      });
      for (var i = 0; i < count; i++) {
        final setIdx = startSet + i;
        if (kg != null) {
          _ctrl('${idx}_${setIdx}_w').text =
              kg.toStringAsFixed(kg == kg.roundToDouble() ? 0 : 1);
        }
        if (reps != null) {
          _ctrl('${idx}_${setIdx}_r').text = reps.toString();
        }
      }
    } else {
      _voiceAddExercise(exId, exName, count, kg, reps);
    }
  }

  void _voiceUpdateSpecificSet(
    String exId, int setIndex, double kg, int? reps,
  ) {
    final idx = _exercises.indexWhere((e) => e.exerciseId == exId);
    if (idx < 0) {
      _showVoiceError('Exercise not in current workout');
      return;
    }
    final zeroIdx = setIndex - 1; // Convert 1-based to 0-based
    if (zeroIdx < 0 || zeroIdx >= _exercises[idx].sets.length) {
      _showVoiceError('Set $setIndex does not exist');
      return;
    }
    if (kg > 0) {
      _ctrl('${idx}_${zeroIdx}_w').text =
          kg.toStringAsFixed(kg == kg.roundToDouble() ? 0 : 1);
    }
    if (reps != null) {
      _ctrl('${idx}_${zeroIdx}_r').text = reps.toString();
    }
    setState(() {});
  }

  void _voiceCompleteExercise(String exId) {
    final idx = _exercises.indexWhere((e) => e.exerciseId == exId);
    if (idx < 0) {
      _showVoiceError('Exercise not in current workout');
      return;
    }
    // Only complete if all sets have values
    if (!_allSetsHaveValues(idx)) {
      _showVoiceError('Fill in all weight/reps before completing');
      return;
    }
    setState(() {
      for (var i = 0; i < _exercises[idx].sets.length; i++) {
        _exercises[idx].sets[i].isCompleted = true;
      }
    });
  }

  void _showVoiceCommandHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VoiceCommandHelpSheet(
        isSmartMode: _voiceService.isSmartMode,
      ),
    );
  }

  void _showVoiceError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  IconData _getCommandIcon(VoiceCommand cmd) {
    if (cmd is AddExerciseCommand) return Icons.add_rounded;
    if (cmd is AddSetsCommand) return Icons.playlist_add_rounded;
    if (cmd is UpdateSetCommand) return Icons.edit_rounded;
    if (cmd is RemoveExerciseCommand) return Icons.remove_circle_outline;
    if (cmd is AddSetToExerciseCommand) return Icons.playlist_add_rounded;
    if (cmd is UpdateSpecificSetCommand) return Icons.edit_rounded;
    if (cmd is CompleteExerciseCommand) return Icons.check_circle_outline;
    return Icons.mic_rounded;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final planExercises =
        ref.watch(workoutPlanExercisesProvider(widget.routineId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: _buildAppBar(),
        floatingActionButton: null,
        body: Stack(
          children: [
            planExercises.when(
              data: (exercises) {
                if (!_isInitialised) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _initialiseWorkout(exercises);
                  });
                }
                return _buildBody();
              },
              loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text('Failed to load exercises\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ),

            // Confirmation card
            if (_pendingAction != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VoiceConfirmationCard(
                  actionText: _pendingAction!.displayText,
                  icon: _getCommandIcon(_pendingAction!.command),
                  onConfirm: () => _executeVoiceAction(_pendingAction!),
                  onCancel: () => setState(() => _pendingAction = null),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // App bar
  // -------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textPrimaryDark),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.of(context).pop();
        },
      ),
      title: Text(
        widget.routineName,
        style: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 4),
              Text(
                _formatDuration(_elapsedSeconds),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Body
  // -------------------------------------------------------------------------

  Widget _buildBody() {
    return Column(
      children: [
        // Rest timer overlay
        if (_showRestTimer) _buildRestTimerBar(),
        // Scrollable exercise list
        Expanded(
          child: _exercises.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: _exercises.length + 1, // +1 for add exercise button
                  itemBuilder: (_, i) {
                    if (i == _exercises.length) return _buildAddExerciseButton();
                    return _buildExerciseCard(i);
                  },
                ),
        ),
        // Bottom finish button
        _buildBottomFinishButton(),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Timer bar
  // -------------------------------------------------------------------------

  Widget _buildTimerBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: AppColors.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_elapsedSeconds),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Rest timer bar
  // -------------------------------------------------------------------------

  Widget _buildRestTimerBar() {
    final progress = _restTotalSeconds > 0
        ? _restSecondsRemaining / _restTotalSeconds
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surfaceVariantDark,
      child: Row(
        children: [
          const Icon(Icons.snooze_rounded,
              color: AppColors.textPrimaryDark, size: 20),
          const SizedBox(width: 10),
          const Text('Rest',
              style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.borderDark,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_restSecondsRemaining}s',
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          // Quick duration chips
          ...[30, 60, 90, 120].map((s) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _restChip(s),
              )),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _dismissRestTimer,
            child: const Icon(Icons.close,
                color: AppColors.textSecondaryDark, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _restChip(int seconds) {
    final isActive = _restTotalSeconds == seconds && _showRestTimer;
    return GestureDetector(
      onTap: () => _startRestTimer(seconds),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color:
              isActive ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderDark,
            width: 1,
          ),
        ),
        child: Text(
          '${seconds}s',
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textSecondaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Exercise card
  // -------------------------------------------------------------------------

  Widget _buildExerciseCard(int exIdx) {
    final exercise = _exercises[exIdx];
    final completedCount = exercise.sets.where((s) => s.isCompleted).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusSmall),
                  ),
                  child: Center(
                    child: Text(
                      '${exIdx + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completedCount / ${exercise.sets.length} sets completed',
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Remove exercise
                GestureDetector(
                  onTap: () => _confirmRemoveExercise(exIdx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                      border: Border.all(color: AppColors.borderDark, width: 1),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Complete All / Undo All icon button
                GestureDetector(
                  onTap: () => _toggleAllSets(exIdx),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _areAllSetsCompleted(exIdx)
                          ? AppColors.primary
                          : (_allSetsHaveValues(exIdx)
                              ? AppColors.primary
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                      border: Border.all(
                        color: _areAllSetsCompleted(exIdx) || _allSetsHaveValues(exIdx)
                            ? AppColors.primary
                            : AppColors.borderDark,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.done_all_rounded,
                      size: 20,
                      color: _areAllSetsCompleted(exIdx)
                          ? AppColors.onPrimary
                          : (_allSetsHaveValues(exIdx)
                              ? AppColors.onPrimary
                              : AppColors.textMutedDark),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantDark.withOpacity(0.4),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 28), // delete column
                  _tableHeader('SET', flex: 1),
                  _tableHeader('PREVIOUS', flex: 2),
                  _tableHeader('KG', flex: 2),
                  _tableHeader(
                    exercise.trackingType == TrackingType.duration
                        ? 'SEC'
                        : 'REPS',
                    flex: 2,
                  ),
                  const SizedBox(width: 40), // checkmark column
                ],
              ),
            ),
          ),

          // Set rows
          ...List.generate(exercise.sets.length,
              (setIdx) => _buildSetRow(exIdx, setIdx)),

          // Add Set button (full width)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _addSet(exIdx),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Set'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.25)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMutedDark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Set row
  // -------------------------------------------------------------------------

  Widget _buildSetRow(int exIdx, int setIdx) {
    final set = _exercises[exIdx].sets[setIdx];
    final exercise = _exercises[exIdx];

    final wKey = '${exIdx}_${setIdx}_w';
    final rKey = '${exIdx}_${setIdx}_r';

    // Pre-fill with planned reps if available
    final repsInitial =
        exercise.plannedReps != null ? exercise.plannedReps.toString() : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: set.isCompleted
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(AppDimensions.borderRadiusSmall),
        ),
        child: Row(
          children: [
            // Delete set button (moved to left)
            SizedBox(
              width: 28,
              child: GestureDetector(
                onTap: () => _removeSet(exIdx, setIdx),
                child: Icon(
                  Icons.remove_circle_outline,
                  size: 16,
                  color: AppColors.textMutedDark,
                ),
              ),
            ),

            // SET #
            Expanded(
              flex: 1,
              child: Text(
                '${setIdx + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: set.isCompleted
                      ? AppColors.primary
                      : AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            // PREVIOUS
            Expanded(
              flex: 2,
              child: Text(
                '--',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMutedDark,
                  fontSize: 13,
                ),
              ),
            ),

            // KG input
            Expanded(
              flex: 2,
              child: _compactInput(
                key: wKey,
                hint: '0',
                enabled: !set.isCompleted,
              ),
            ),

            // REPS / DURATION input
            Expanded(
              flex: 2,
              child: _compactInput(
                key: rKey,
                hint: repsInitial.isNotEmpty ? repsInitial : '0',
                initialValue:
                    repsInitial.isNotEmpty && !_controllers.containsKey(rKey)
                        ? repsInitial
                        : null,
                enabled: !set.isCompleted,
              ),
            ),

            // Checkmark
            SizedBox(
              width: 40,
              child: GestureDetector(
                onTap: () => _toggleSetComplete(exIdx, setIdx),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: set.isCompleted
                        ? AppColors.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: set.isCompleted
                          ? AppColors.primary
                          : AppColors.borderDark,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: set.isCompleted
                        ? AppColors.onPrimary
                        : AppColors.textMutedDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Compact numeric input field
  // -------------------------------------------------------------------------

  Widget _compactInput({
    required String key,
    String hint = '',
    String? initialValue,
    bool enabled = true,
  }) {
    final controller = _ctrl(key, initialValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 34,
        child: TextField(
          controller: controller,
          enabled: enabled,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          style: TextStyle(
            color: enabled
                ? AppColors.textPrimaryDark
                : AppColors.textSecondaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMutedDark,
              fontSize: 14,
            ),
            filled: true,
            fillColor: enabled
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantDark.withOpacity(0.4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Add exercise mid-workout
  // -------------------------------------------------------------------------

  void _addExerciseMidWorkout() async {
    final exercises = await ref.read(allExercisesProvider.future);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MidWorkoutExercisePicker(
        exercises: exercises,
        onExercisesSelected: (selected) async {
          final repo = ref.read(workoutRepositoryProvider);
          for (final ex in selected) {
            final logExId = _uuid.v4();
            await repo.insertWorkoutLogExercise(
              WorkoutLogExercisesCompanion.insert(
                id: logExId,
                workoutLogId: _workoutLogId!,
                exerciseId: ex.id,
                trackingType: TrackingType.reps,
              ),
            );
            setState(() {
              _exercises.add(ExerciseEntry(
                exerciseId: ex.id,
                exerciseName: ex.name,
                sets: List.generate(3, (_) => SetEntry(id: _uuid.v4())),
                trackingType: TrackingType.reps,
                workoutLogExerciseId: logExId,
              ));
            });
          }
        },
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _addExerciseMidWorkout,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Exercise'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            side: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Bottom finish button
  // -------------------------------------------------------------------------

  Widget _buildBottomFinishButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: const Border(
          top: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Info button
              GestureDetector(
                onTap: _showVoiceCommandHelp,
                child: Container(
                  width: 40,
                  height: 52,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondaryDark,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Finish button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _finishWorkout,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onPrimary))
                        : const Icon(Icons.check_circle_rounded, size: 22),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Finish Workout',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.borderRadiusMedium),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Mic button
              GestureDetector(
                onTap: _startVoiceListening,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 26),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Voice Command Help Sheet
// ---------------------------------------------------------------------------

class _VoiceCommandHelpSheet extends StatelessWidget {
  final bool isSmartMode;
  const _VoiceCommandHelpSheet({required this.isSmartMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.mic_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Voice Commands',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Mode badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSmartMode
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSmartMode
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.borderDark,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSmartMode ? Icons.auto_awesome : Icons.text_fields_rounded,
                    color: isSmartMode ? AppColors.primary : AppColors.textSecondaryDark,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isSmartMode ? 'AI Mode · Gemini Nano' : 'Basic Mode · Pattern Matching',
                    style: TextStyle(
                      color: isSmartMode ? AppColors.primary : AppColors.textSecondaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Command list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Add Exercises', Icons.add_circle_outline, [
                    '"Add bicep curl"',
                    '"3 sets of bench press at 80kg"',
                    '"3 sets of curls 10kg 12 reps"',
                  ]),
                  _buildSection('Update Sets', Icons.edit_outlined, [
                    '"Bench press 80kg 8 reps"',
                    '"Curls at 12kg"',
                    if (isSmartMode) '"Set 2 of bench press 90kg 6 reps"',
                  ]),
                  _buildSection('Add Sets to Existing', Icons.playlist_add, [
                    '"Add 2 sets to bench press"',
                    '"One more set of curls"',
                  ]),
                  _buildSection('Remove Exercise', Icons.remove_circle_outline, [
                    '"Remove bench press"',
                    '"Delete bicep curl"',
                  ]),
                  _buildSection('Complete Exercise', Icons.check_circle_outline, [
                    '"Complete bench press"',
                    '"Mark curls as done"',
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> examples) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...examples.map((ex) => Padding(
                padding: const EdgeInsets.only(left: 26, bottom: 4),
                child: Text(
                  ex,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mid-workout exercise picker
// ---------------------------------------------------------------------------

class _MidWorkoutExercisePicker extends StatefulWidget {
  final List<ExerciseData> exercises;
  final Function(List<ExerciseData>) onExercisesSelected;

  const _MidWorkoutExercisePicker({
    required this.exercises,
    required this.onExercisesSelected,
  });

  @override
  State<_MidWorkoutExercisePicker> createState() => _MidWorkoutExercisePickerState();
}

class _MidWorkoutExercisePickerState extends State<_MidWorkoutExercisePicker> {
  String _search = '';
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? widget.exercises
        : widget.exercises.where((e) => e.name.toLowerCase().contains(_search)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMutedDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Exercise',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondaryDark),
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: const TextStyle(color: AppColors.textMutedDark),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.surfaceVariantDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (_, i) {
                final ex = filtered[i];
                final selected = _selectedIds.contains(ex.id);
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: selected
                          ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                          : Text(
                              ex.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    ex.name,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    ex.category.displayName,
                    style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                  ),
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedIds.remove(ex.id);
                    } else {
                      _selectedIds.add(ex.id);
                    }
                  }),
                );
              },
            ),
          ),
          // Add button
          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderDark)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final selected = widget.exercises.where((e) => _selectedIds.contains(e.id)).toList();
                      widget.onExercisesSelected(selected);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add ${_selectedIds.length} Exercise${_selectedIds.length > 1 ? "s" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
