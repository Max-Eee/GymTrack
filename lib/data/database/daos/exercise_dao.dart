import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';
import '../../../models/enums.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises, FavouriteExercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase> with _$ExerciseDaoMixin {
  ExerciseDao(AppDatabase db) : super(db);

  // Get all exercises
  Stream<List<ExerciseData>> watchAllExercises() {
    return select(exercises).watch();
  }

  Future<List<ExerciseData>> getAllExercises() {
    return select(exercises).get();
  }

  // Get exercise by ID
  Stream<ExerciseData?> watchExercise(String id) {
    return (select(exercises)..where((e) => e.id.equals(id))).watchSingleOrNull();
  }

  Future<ExerciseData?> getExercise(String id) {
    return (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  // Search exercises
  Future<List<ExerciseData>> searchExercises(String query) {
    final searchQuery = '%${query.toLowerCase()}%';
    return (select(exercises)
          ..where((e) => e.name.lower().like(searchQuery)))
        .get();
  }

  Stream<List<ExerciseData>> watchSearchExercises(String query) {
    final searchQuery = '%${query.toLowerCase()}%';
    return (select(exercises)
          ..where((e) => e.name.lower().like(searchQuery)))
        .watch();
  }

  // Filter exercises
  Future<List<ExerciseData>> filterExercises({
    List<Muscle>? primaryMuscles,
    List<CategoryType>? categories,
    List<LevelType>? levels,
    List<EquipmentType>? equipment,
  }) {
    var query = select(exercises);

    if (categories != null && categories.isNotEmpty) {
      query = query..where((e) => e.category.isIn(categories.map((c) => c.index)));
    }

    if (levels != null && levels.isNotEmpty) {
      query = query..where((e) => e.level.isIn(levels.map((l) => l.index)));
    }

    if (equipment != null && equipment.isNotEmpty) {
      query = query..where((e) => e.equipment.isIn(equipment.map((eq) => eq.index)));
    }

    return query.get();
  }

  // Get favorite exercises
  Stream<List<ExerciseData>> watchFavoriteExercises() async* {
    await for (final favs in select(favouriteExercises).watch()) {
      if (favs.isEmpty) {
        yield [];
        continue;
      }
      
      final exerciseIds = favs.map((f) => f.exerciseId).toList();
      final exercises = await (select(this.exercises)
            ..where((e) => e.id.isIn(exerciseIds)))
          .get();
      yield exercises;
    }
  }

  Future<List<ExerciseData>> getFavoriteExercises() async {
    final favs = await select(favouriteExercises).get();
    if (favs.isEmpty) return [];

    final exerciseIds = favs.map((f) => f.exerciseId).toList();
    return (select(exercises)..where((e) => e.id.isIn(exerciseIds))).get();
  }

  // Check if exercise is favorite
  Stream<bool> watchIsFavorite(String exerciseId) async* {
    await for (final fav in (select(favouriteExercises)
          ..where((e) => e.exerciseId.equals(exerciseId)))
        .watchSingleOrNull()) {
      yield fav != null;
    }
  }

  Future<bool> isFavorite(String exerciseId) async {
    final fav = await (select(favouriteExercises)
          ..where((e) => e.exerciseId.equals(exerciseId)))
        .getSingleOrNull();
    return fav != null;
  }

  // Toggle favorite
  Future<void> toggleFavorite(String exerciseId) async {
    final existing = await (select(favouriteExercises)
          ..where((e) => e.exerciseId.equals(exerciseId)))
        .getSingleOrNull();

    if (existing != null) {
      await (delete(favouriteExercises)
            ..where((e) => e.exerciseId.equals(exerciseId)))
          .go();
    } else {
      await into(favouriteExercises).insert(
        FavouriteExercisesCompanion.insert(exerciseId: exerciseId),
      );
    }
  }

  // Bulk insert exercises
  Future<void> insertExercises(List<ExercisesCompanion> exerciseList) async {
    await batch((batch) {
      batch.insertAll(exercises, exerciseList, mode: InsertMode.insertOrReplace);
    });
  }

  // Insert single exercise
  Future<int> insertExercise(ExercisesCompanion exercise) {
    return into(exercises).insert(exercise, mode: InsertMode.insertOrReplace);
  }

  // Update exercise
  Future<bool> updateExercise(ExerciseData exercise) {
    return update(exercises).replace(exercise);
  }

  // Delete single exercise
  Future<int> deleteExercise(String id) {
    return (delete(exercises)..where((e) => e.id.equals(id))).go();
  }

  // Delete all exercises
  Future<void> deleteAllExercises() async {
    await delete(exercises).go();
  }

  // Get exercise count
  Future<int> getExerciseCount() async {
    final count = exercises.id.count();
    final query = selectOnly(exercises)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
