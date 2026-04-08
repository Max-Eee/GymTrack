import '../database/app_database.dart';
import '../database/daos/workout_dao.dart';

class WorkoutRepository {
  final WorkoutDao _workoutDao;

  WorkoutRepository(this._workoutDao);

  // Workout Plans - Streams
  Stream<List<WorkoutPlanData>> watchAllWorkoutPlans() => 
      _workoutDao.watchAllWorkoutPlans();
  
  Stream<List<WorkoutPlanData>> watchSystemRoutines() => 
      _workoutDao.watchSystemRoutines();
  
  Stream<WorkoutPlanData?> watchWorkoutPlan(String id) => 
      _workoutDao.watchWorkoutPlan(id);
  
  Stream<List<WorkoutPlanExerciseData>> watchWorkoutPlanExercises(String planId) => 
      _workoutDao.watchWorkoutPlanExercises(planId);

  // Workout Plans - Futures
  Future<List<WorkoutPlanData>> getAllWorkoutPlans() => 
      _workoutDao.getAllWorkoutPlans();
  
  Future<WorkoutPlanData?> getWorkoutPlan(String id) => 
      _workoutDao.getWorkoutPlan(id);
  
  Future<List<WorkoutPlanExerciseData>> getWorkoutPlanExercises(String planId) => 
      _workoutDao.getWorkoutPlanExercises(planId);
  
  Future<int> insertWorkoutPlan(WorkoutPlansCompanion plan) => 
      _workoutDao.insertWorkoutPlan(plan);
  
  Future<bool> updateWorkoutPlan(WorkoutPlanData plan) => 
      _workoutDao.updateWorkoutPlan(plan);
  
  Future<int> deleteWorkoutPlan(String id) => 
      _workoutDao.deleteWorkoutPlan(id);
  
  Future<int> insertWorkoutPlanExercise(WorkoutPlanExercisesCompanion exercise) => 
      _workoutDao.insertWorkoutPlanExercise(exercise);
  
  Future<int> deleteWorkoutPlanExercise(String id) => 
      _workoutDao.deleteWorkoutPlanExercise(id);
  
  Future<bool> updateWorkoutPlanExercise(WorkoutPlanExerciseData exercise) =>
      _workoutDao.updateWorkoutPlanExercise(exercise);
  
  Future<void> updateExerciseOrder(String planId, List<String> exerciseIds) => 
      _workoutDao.updateExerciseOrder(planId, exerciseIds);

  // Workout Logs - Streams
  Stream<List<WorkoutLogData>> watchAllWorkoutLogs() => 
      _workoutDao.watchAllWorkoutLogs();
  
  Stream<WorkoutLogData?> watchActiveWorkout() => 
      _workoutDao.watchActiveWorkout();
  
  Stream<WorkoutLogData?> watchWorkoutLog(String id) => 
      _workoutDao.watchWorkoutLog(id);
  
  Stream<List<WorkoutLogExerciseData>> watchWorkoutLogExercises(String logId) => 
      _workoutDao.watchWorkoutLogExercises(logId);
  
  Stream<List<SetLogData>> watchSetLogs(String workoutLogExerciseId) => 
      _workoutDao.watchSetLogs(workoutLogExerciseId);

  // Workout Logs - Futures
  Future<List<WorkoutLogData>> getWorkoutLogsByDateRange(DateTime start, DateTime end) => 
      _workoutDao.getWorkoutLogsByDateRange(start, end);
  
  Future<WorkoutLogData?> getActiveWorkout() => 
      _workoutDao.getActiveWorkout();
  
  Future<WorkoutLogData?> getWorkoutLog(String id) => 
      _workoutDao.getWorkoutLog(id);
  
  Future<List<WorkoutLogExerciseData>> getWorkoutLogExercises(String logId) => 
      _workoutDao.getWorkoutLogExercises(logId);
  
  Future<List<SetLogData>> getSetLogs(String workoutLogExerciseId) => 
      _workoutDao.getSetLogs(workoutLogExerciseId);
  
  Future<int> insertWorkoutLog(WorkoutLogsCompanion log) => 
      _workoutDao.insertWorkoutLog(log);
  
  Future<bool> updateWorkoutLog(WorkoutLogData log) => 
      _workoutDao.updateWorkoutLog(log);
  
  Future<int> deleteWorkoutLog(String id) => 
      _workoutDao.deleteWorkoutLog(id);
  
  Future<int> insertWorkoutLogExercise(WorkoutLogExercisesCompanion exercise) => 
      _workoutDao.insertWorkoutLogExercise(exercise);
  
  Future<int> insertSetLog(SetLogsCompanion setLog) => 
      _workoutDao.insertSetLog(setLog);
  
  Future<bool> updateSetLog(SetLogData setLog) => 
      _workoutDao.updateSetLog(setLog);
  
  Future<int> deleteSetLog(String id) => 
      _workoutDao.deleteSetLog(id);

  // Analytics
  Future<int> getWorkoutCountInDateRange(DateTime start, DateTime end) => 
      _workoutDao.getWorkoutCountInDateRange(start, end);
  
  Future<double> getTotalVolumeInDateRange(DateTime start, DateTime end) => 
      _workoutDao.getTotalVolumeInDateRange(start, end);
}
