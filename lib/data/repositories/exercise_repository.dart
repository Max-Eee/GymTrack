import '../database/app_database.dart';
import '../database/daos/exercise_dao.dart';
import '../../models/enums.dart';

class ExerciseRepository {
  final ExerciseDao _exerciseDao;

  ExerciseRepository(this._exerciseDao);

  // Streams
  Stream<List<ExerciseData>> watchAllExercises() => _exerciseDao.watchAllExercises();
  
  Stream<ExerciseData?> watchExercise(String id) => _exerciseDao.watchExercise(id);
  
  Stream<List<ExerciseData>> watchSearchExercises(String query) => 
      _exerciseDao.watchSearchExercises(query);
  
  Stream<List<ExerciseData>> watchFavoriteExercises() => 
      _exerciseDao.watchFavoriteExercises();
  
  Stream<bool> watchIsFavorite(String exerciseId) => 
      _exerciseDao.watchIsFavorite(exerciseId);

  // Futures
  Future<List<ExerciseData>> getAllExercises() => _exerciseDao.getAllExercises();
  
  Future<ExerciseData?> getExercise(String id) => _exerciseDao.getExercise(id);
  
  Future<List<ExerciseData>> searchExercises(String query) => 
      _exerciseDao.searchExercises(query);
  
  Future<List<ExerciseData>> filterExercises({
    List<Muscle>? primaryMuscles,
    List<CategoryType>? categories,
    List<LevelType>? levels,
    List<EquipmentType>? equipment,
  }) => _exerciseDao.filterExercises(
        primaryMuscles: primaryMuscles,
        categories: categories,
        levels: levels,
        equipment: equipment,
      );
  
  Future<List<ExerciseData>> getFavoriteExercises() => 
      _exerciseDao.getFavoriteExercises();
  
  Future<bool> isFavorite(String exerciseId) => 
      _exerciseDao.isFavorite(exerciseId);
  
  Future<void> toggleFavorite(String exerciseId) => 
      _exerciseDao.toggleFavorite(exerciseId);
  
  Future<void> insertExercises(List<ExercisesCompanion> exercises) => 
      _exerciseDao.insertExercises(exercises);

  Future<int> insertExercise(ExercisesCompanion exercise) =>
      _exerciseDao.insertExercise(exercise);
  
  Future<bool> updateExercise(ExerciseData exercise) =>
      _exerciseDao.updateExercise(exercise);
  
  Future<int> deleteExercise(String id) =>
      _exerciseDao.deleteExercise(id);
  
  Future<int> getExerciseCount() => _exerciseDao.getExerciseCount();
}
