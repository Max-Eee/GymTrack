import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../models/enums.dart';
import 'app_providers.dart';
import 'user_providers.dart';

// All Exercises Stream
final allExercisesProvider = StreamProvider<List<ExerciseData>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchAllExercises();
});

// Exercise by ID
final exerciseProvider = StreamProvider.family<ExerciseData?, String>((ref, id) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchExercise(id);
});

// Search Query State
final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

// Searched Exercises
final searchedExercisesProvider = StreamProvider<List<ExerciseData>>((ref) {
  final query = ref.watch(exerciseSearchQueryProvider);
  final repo = ref.watch(exerciseRepositoryProvider);
  
  if (query.isEmpty) {
    return repo.watchAllExercises();
  }
  
  return repo.watchSearchExercises(query);
});

// Favorite Exercises
final favoriteExercisesProvider = StreamProvider<List<ExerciseData>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchFavoriteExercises();
});

// Is Exercise Favorite
final isExerciseFavoriteProvider = StreamProvider.family<bool, String>((ref, exerciseId) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchIsFavorite(exerciseId);
});

// Filter State
final exerciseFilterCategoriesProvider = StateProvider<List<CategoryType>>((ref) => []);
final exerciseFilterLevelsProvider = StateProvider<List<LevelType>>((ref) => []);
final exerciseFilterEquipmentProvider = StateProvider<List<EquipmentType>>((ref) => []);
final exerciseFilterMusclesProvider = StateProvider<List<Muscle>>((ref) => []);

// Show Only Favorites Toggle
final showOnlyFavoritesProvider = StateProvider<bool>((ref) => false);

// Show Only Custom Exercises Toggle
final showOnlyCustomProvider = StateProvider<bool>((ref) => false);

// Show Only My Equipment Toggle
final showOnlyMyEquipmentProvider = StateProvider<bool>((ref) => false);

// Filtered Exercises – combines search, category/level/equipment/muscle filters, and favorites toggle.
final filteredExercisesProvider = FutureProvider<List<ExerciseData>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final categories = ref.watch(exerciseFilterCategoriesProvider);
  final levels = ref.watch(exerciseFilterLevelsProvider);
  final equipment = ref.watch(exerciseFilterEquipmentProvider);
  final muscles = ref.watch(exerciseFilterMusclesProvider);
  final searchQuery = ref.watch(exerciseSearchQueryProvider).trim().toLowerCase();
  final showOnlyFavorites = ref.watch(showOnlyFavoritesProvider);
  final showOnlyCustom = ref.watch(showOnlyCustomProvider);
  final showOnlyMyEquipment = ref.watch(showOnlyMyEquipmentProvider);

  // Base list: apply category/level/equipment/muscle filters at the DB level.
  List<ExerciseData> exercises;
  if (categories.isEmpty && levels.isEmpty && equipment.isEmpty && muscles.isEmpty) {
    exercises = await repo.getAllExercises();
  } else {
    exercises = await repo.filterExercises(
      categories: categories.isEmpty ? null : categories,
      levels: levels.isEmpty ? null : levels,
      equipment: equipment.isEmpty ? null : equipment,
      primaryMuscles: muscles.isEmpty ? null : muscles,
    );
  }

  // Apply search in-memory (name + aliases).
  if (searchQuery.isNotEmpty) {
    exercises = exercises.where((e) =>
      e.name.toLowerCase().contains(searchQuery) ||
      e.aliases.any((a) => a.toLowerCase().contains(searchQuery))
    ).toList();
  }

  // Apply favorites-only filter.
  if (showOnlyFavorites) {
    final favorites = await repo.getFavoriteExercises();
    final favoriteIds = favorites.map((f) => f.id).toSet();
    exercises = exercises.where((e) => favoriteIds.contains(e.id)).toList();
  }

  // Apply custom-only filter.
  if (showOnlyCustom) {
    exercises = exercises.where((e) => e.isCustom).toList();
  }

  // Apply my-equipment filter.
  if (showOnlyMyEquipment) {
    final userEquipmentAsync = ref.watch(userEquipmentProvider);
    final userEquipmentList = userEquipmentAsync.valueOrNull ?? [];
    final myEquipmentTypes = userEquipmentList.map((e) => e.equipmentType).toSet();
    // Always include bodyOnly exercises
    myEquipmentTypes.add(EquipmentType.bodyOnly);
    exercises = exercises.where((e) =>
      e.equipment == null || myEquipmentTypes.contains(e.equipment)
    ).toList();
  }

  return exercises;
});

// Toggle Favorite Action
final toggleExerciseFavoriteProvider = Provider.autoDispose.family<Future<void> Function(), String>((ref, exerciseId) {
  return () async {
    final repo = ref.read(exerciseRepositoryProvider);
    await repo.toggleFavorite(exerciseId);
    // Refresh filtered list when favorites-only filter is active.
    if (ref.read(showOnlyFavoritesProvider)) {
      ref.invalidate(filteredExercisesProvider);
    }
  };
});

// Exercise Count
final exerciseCountProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.getExerciseCount();
});
