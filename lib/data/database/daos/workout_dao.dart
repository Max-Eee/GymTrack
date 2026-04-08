import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [WorkoutPlans, WorkoutPlanExercises, WorkoutLogs, WorkoutLogExercises, SetLogs])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(AppDatabase db) : super(db);

  // Workout Plans
  Stream<List<WorkoutPlanData>> watchAllWorkoutPlans() {
    return (select(workoutPlans)
          ..where((p) => p.isSystemRoutine.equals(false))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .watch();
  }

  Future<List<WorkoutPlanData>> getAllWorkoutPlans() {
    return (select(workoutPlans)
          ..where((p) => p.isSystemRoutine.equals(false))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .get();
  }

  Stream<List<WorkoutPlanData>> watchSystemRoutines() {
    return (select(workoutPlans)
          ..where((p) => p.isSystemRoutine.equals(true)))
        .watch();
  }

  Stream<WorkoutPlanData?> watchWorkoutPlan(String id) {
    return (select(workoutPlans)..where((p) => p.id.equals(id))).watchSingleOrNull();
  }

  Future<WorkoutPlanData?> getWorkoutPlan(String id) {
    return (select(workoutPlans)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertWorkoutPlan(WorkoutPlansCompanion plan) {
    return into(workoutPlans).insert(plan);
  }

  Future<bool> updateWorkoutPlan(WorkoutPlanData plan) {
    return update(workoutPlans).replace(plan);
  }

  Future<int> deleteWorkoutPlan(String id) {
    return (delete(workoutPlans)..where((p) => p.id.equals(id))).go();
  }

  // Workout Plan Exercises
  Stream<List<WorkoutPlanExerciseData>> watchWorkoutPlanExercises(String planId) {
    return (select(workoutPlanExercises)
          ..where((e) => e.workoutPlanId.equals(planId))
          ..orderBy([(e) => OrderingTerm(expression: e.order)]))
        .watch();
  }

  Future<List<WorkoutPlanExerciseData>> getWorkoutPlanExercises(String planId) {
    return (select(workoutPlanExercises)
          ..where((e) => e.workoutPlanId.equals(planId))
          ..orderBy([(e) => OrderingTerm(expression: e.order)]))
        .get();
  }

  Future<int> insertWorkoutPlanExercise(WorkoutPlanExercisesCompanion exercise) {
    return into(workoutPlanExercises).insert(exercise);
  }

  Future<int> deleteWorkoutPlanExercise(String id) {
    return (delete(workoutPlanExercises)..where((e) => e.id.equals(id))).go();
  }

  Future<bool> updateWorkoutPlanExercise(WorkoutPlanExerciseData exercise) {
    return update(workoutPlanExercises).replace(exercise);
  }

  Future<void> updateExerciseOrder(String planId, List<String> exerciseIds) async {
    await transaction(() async {
      for (var i = 0; i < exerciseIds.length; i++) {
        await (update(workoutPlanExercises)
              ..where((e) => e.id.equals(exerciseIds[i])))
            .write(WorkoutPlanExercisesCompanion(order: Value(i)));
      }
    });
  }

  // Workout Logs
  Stream<List<WorkoutLogData>> watchAllWorkoutLogs() {
    return (select(workoutLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .watch();
  }

  Future<List<WorkoutLogData>> getWorkoutLogsByDateRange(DateTime start, DateTime end) {
    return (select(workoutLogs)
          ..where((l) => l.date.isBiggerOrEqualValue(start) & l.date.isSmallerOrEqualValue(end))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
  }

  Stream<WorkoutLogData?> watchActiveWorkout() {
    return (select(workoutLogs)
          ..where((l) => l.inProgress.equals(true)))
        .watchSingleOrNull();
  }

  Future<WorkoutLogData?> getActiveWorkout() {
    return (select(workoutLogs)
          ..where((l) => l.inProgress.equals(true)))
        .getSingleOrNull();
  }

  Stream<WorkoutLogData?> watchWorkoutLog(String id) {
    return (select(workoutLogs)..where((l) => l.id.equals(id))).watchSingleOrNull();
  }

  Future<WorkoutLogData?> getWorkoutLog(String id) {
    return (select(workoutLogs)..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertWorkoutLog(WorkoutLogsCompanion log) {
    return into(workoutLogs).insert(log);
  }

  Future<bool> updateWorkoutLog(WorkoutLogData log) {
    return update(workoutLogs).replace(log);
  }

  Future<int> deleteWorkoutLog(String id) {
    return (delete(workoutLogs)..where((l) => l.id.equals(id))).go();
  }

  // Workout Log Exercises
  Stream<List<WorkoutLogExerciseData>> watchWorkoutLogExercises(String logId) {
    return (select(workoutLogExercises)
          ..where((e) => e.workoutLogId.equals(logId)))
        .watch();
  }

  Future<List<WorkoutLogExerciseData>> getWorkoutLogExercises(String logId) {
    return (select(workoutLogExercises)
          ..where((e) => e.workoutLogId.equals(logId)))
        .get();
  }

  Future<int> insertWorkoutLogExercise(WorkoutLogExercisesCompanion exercise) {
    return into(workoutLogExercises).insert(exercise);
  }

  // Set Logs
  Stream<List<SetLogData>> watchSetLogs(String workoutLogExerciseId) {
    return (select(setLogs)
          ..where((s) => s.workoutLogExerciseId.equals(workoutLogExerciseId))
          ..orderBy([(s) => OrderingTerm(expression: s.order)]))
        .watch();
  }

  Future<List<SetLogData>> getSetLogs(String workoutLogExerciseId) {
    return (select(setLogs)
          ..where((s) => s.workoutLogExerciseId.equals(workoutLogExerciseId))
          ..orderBy([(s) => OrderingTerm(expression: s.order)]))
        .get();
  }

  Future<int> insertSetLog(SetLogsCompanion setLog) {
    return into(setLogs).insert(setLog);
  }

  Future<bool> updateSetLog(SetLogData setLog) {
    return update(setLogs).replace(setLog);
  }

  Future<int> deleteSetLog(String id) {
    return (delete(setLogs)..where((s) => s.id.equals(id))).go();
  }

  // Analytics queries
  Future<int> getWorkoutCountInDateRange(DateTime start, DateTime end) async {
    final count = workoutLogs.id.count();
    final query = selectOnly(workoutLogs)
      ..addColumns([count])
      ..where(workoutLogs.date.isBiggerOrEqualValue(start) & 
              workoutLogs.date.isSmallerOrEqualValue(end) &
              workoutLogs.inProgress.equals(false));
    
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<double> getTotalVolumeInDateRange(DateTime start, DateTime end) async {
    // Calculate total volume (weight * reps) for all sets in date range
    final logs = await getWorkoutLogsByDateRange(start, end);
    double totalVolume = 0;

    for (final log in logs) {
      if (log.inProgress) continue;
      
      final logExercises = await getWorkoutLogExercises(log.id);
      for (final logExercise in logExercises) {
        final sets = await getSetLogs(logExercise.id);
        for (final set in sets) {
          if (!set.isWarmUp && set.weight != null && set.reps != null) {
            totalVolume += set.weight! * set.reps!;
          }
        }
      }
    }

    return totalVolume;
  }
}
