import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../models/preset_pack.dart';
import '../../models/enums.dart';
import '../database/app_database.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/workout_repository.dart';

/// Adds preset routine packs to the database.
class PresetPackService {
  final WorkoutRepository _workoutRepo;
  final ExerciseRepository _exerciseRepo;
  static const _uuid = Uuid();

  PresetPackService(this._workoutRepo, this._exerciseRepo);

  /// Add all routines from a pack. Returns the count of routines added.
  Future<int> addPack(PresetPack pack) async {
    final existingPlans = await _workoutRepo.getAllWorkoutPlans();
    final existingNames =
        existingPlans.map((p) => p.name.toLowerCase()).toSet();

    int added = 0;
    for (final routine in pack.routines) {
      if (existingNames.contains(routine.name.toLowerCase())) continue;
      await _addRoutine(routine);
      added++;
    }
    return added;
  }

  /// Add a single preset routine. Returns true if added, false if duplicate.
  Future<bool> addSingleRoutine(PresetRoutine routine) async {
    final existingPlans = await _workoutRepo.getAllWorkoutPlans();
    final exists = existingPlans
        .any((p) => p.name.toLowerCase() == routine.name.toLowerCase());
    if (exists) return false;

    await _addRoutine(routine);
    return true;
  }

  /// Check which routine names from a pack already exist.
  Future<Set<String>> getExistingRoutineNames(PresetPack pack) async {
    final existingPlans = await _workoutRepo.getAllWorkoutPlans();
    final existingNames =
        existingPlans.map((p) => p.name.toLowerCase()).toSet();

    return pack.routines
        .where((r) => existingNames.contains(r.name.toLowerCase()))
        .map((r) => r.name)
        .toSet();
  }

  Future<void> _addRoutine(PresetRoutine routine) async {
    final planId = _uuid.v4();

    await _workoutRepo.insertWorkoutPlan(
      WorkoutPlansCompanion.insert(
        id: planId,
        name: routine.name,
        notes: drift.Value(routine.notes),
        isSystemRoutine: const drift.Value(false),
      ),
    );

    // Resolve exercise names → IDs
    final allExercises = await _exerciseRepo.getAllExercises();
    final nameToId = <String, String>{};
    for (final ex in allExercises) {
      nameToId[ex.name.toLowerCase()] = ex.id;
    }

    for (int i = 0; i < routine.exercises.length; i++) {
      final preset = routine.exercises[i];
      var exerciseId = nameToId[preset.exerciseName.toLowerCase()];

      // Auto-create exercise if it doesn't exist in the database
      if (exerciseId == null) {
        exerciseId = _uuid.v4();
        await _exerciseRepo.insertExercise(
          ExercisesCompanion.insert(
            id: exerciseId,
            name: preset.exerciseName,
            aliases: const [],
            primaryMuscles: const [],
            secondaryMuscles: const [],
            level: LevelType.beginner,
            category: CategoryType.strength,
            instructions: const [],
            tips: const [],
            isCustom: const drift.Value(true),
            dateCreated: drift.Value(DateTime.now()),
          ),
        );
        nameToId[preset.exerciseName.toLowerCase()] = exerciseId;
      }

      await _workoutRepo.insertWorkoutPlanExercise(
        WorkoutPlanExercisesCompanion.insert(
          id: _uuid.v4(),
          workoutPlanId: planId,
          exerciseId: exerciseId,
          sets: preset.sets,
          reps: drift.Value(preset.trackingType == TrackingType.reps
              ? preset.reps
              : null),
          exerciseDuration: drift.Value(preset.durationSeconds),
          order: drift.Value(i),
          trackingType: preset.trackingType,
        ),
      );
    }
  }
}
