import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../models/enums.dart';
import 'app_providers.dart';

// All Workout Plans
final allWorkoutPlansProvider = StreamProvider<List<WorkoutPlanData>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchAllWorkoutPlans();
});

// System Routines
final systemRoutinesProvider = StreamProvider<List<WorkoutPlanData>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchSystemRoutines();
});

// Workout Plan by ID
final workoutPlanProvider = StreamProvider.family<WorkoutPlanData?, String>((ref, id) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchWorkoutPlan(id);
});

// Workout Plan Exercises
final workoutPlanExercisesProvider = StreamProvider.family<List<WorkoutPlanExerciseData>, String>((ref, planId) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchWorkoutPlanExercises(planId);
});

// All Workout Logs
final allWorkoutLogsProvider = StreamProvider<List<WorkoutLogData>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchAllWorkoutLogs();
});

// Active Workout
final activeWorkoutProvider = StreamProvider<WorkoutLogData?>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchActiveWorkout();
});

// Workout Log by ID
final workoutLogProvider = StreamProvider.family<WorkoutLogData?, String>((ref, id) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchWorkoutLog(id);
});

// Workout Log Exercises
final workoutLogExercisesProvider = StreamProvider.family<List<WorkoutLogExerciseData>, String>((ref, logId) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchWorkoutLogExercises(logId);
});

// Set Logs
final setLogsProvider = StreamProvider.family<List<SetLogData>, String>((ref, workoutLogExerciseId) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchSetLogs(workoutLogExerciseId);
});

// Analytics - Workout Count
final workoutCountProvider = FutureProvider.family<int, DateRange>((ref, dateRange) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getWorkoutCountInDateRange(dateRange.start, dateRange.end);
});

// Analytics - Total Volume
final totalVolumeProvider = FutureProvider.family<double, DateRange>((ref, dateRange) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getTotalVolumeInDateRange(dateRange.start, dateRange.end);
});

// Helper class for date ranges
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════════
// Weekly Muscle Activity — aggregates muscle hit counts for the heat map
// ═══════════════════════════════════════════════════════════════════════════
final weeklyMuscleActivityProvider =
    FutureProvider.family<Map<Muscle, int>, DateRange>((ref, range) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final logs = await workoutRepo.getWorkoutLogsByDateRange(range.start, range.end);
  final counts = <Muscle, int>{};

  for (final log in logs) {
    if (log.inProgress) continue;
    final logExercises = await workoutRepo.getWorkoutLogExercises(log.id);
    for (final logEx in logExercises) {
      final exercise = await exerciseRepo.getExercise(logEx.exerciseId);
      if (exercise == null) continue;
      for (final m in exercise.primaryMuscles) {
        counts[m] = (counts[m] ?? 0) + 2; // primary muscles count double
      }
      for (final m in exercise.secondaryMuscles) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
  }
  return counts;
});
