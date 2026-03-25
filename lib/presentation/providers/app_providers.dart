import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/database_seed_service.dart';
import '../../data/services/add_custom_exercises.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Storage Service Provider
final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return StorageService.getInstance();
});

// Repository Providers
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExerciseRepository(db.exerciseDao);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db.workoutDao);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return UserRepository(db.userDao);
});

// Database Seed Service Provider
final databaseSeedServiceProvider = Provider<DatabaseSeedService>((ref) {
  final db = ref.watch(databaseProvider);
  return DatabaseSeedService(db);
});

// Custom Exercise Adder Provider
final customExerciseAdderProvider = Provider<CustomExerciseAdder>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomExerciseAdder(db);
});

// App Initialization Provider
final appInitializationProvider = FutureProvider<bool>((ref) async {
  final storage = await ref.watch(storageServiceProvider.future);
  final seedService = ref.watch(databaseSeedServiceProvider);
  final customExerciseAdder = ref.watch(customExerciseAdderProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  if (storage.isFirstLaunch) {
    try {
      await seedService.seedExercises();
      await customExerciseAdder.addCustomExercises();
      await storage.setFirstLaunchComplete();
    } catch (e) {
      print('Seed warning: $e');
    }
  } else {
    // Re-seed if exercises are missing (e.g. after schema fix)
    final count = await exerciseRepo.getExerciseCount();
    if (count == 0) {
      try {
        await seedService.seedExercises();
        await customExerciseAdder.addCustomExercises();
      } catch (e) {
        print('Re-seed warning: $e');
      }
    } else {
      // Always try to add custom exercises if missing
      try {
        await customExerciseAdder.addCustomExercises();
      } catch (e) {
        print('Custom exercises warning: $e');
      }
    }
  }

  final count = await exerciseRepo.getExerciseCount();
  print('App initialized with $count exercises');
  
  return true;
});

// Tab navigation provider - used by dashboard quick actions
final currentTabProvider = StateProvider<int>((ref) => 0);
