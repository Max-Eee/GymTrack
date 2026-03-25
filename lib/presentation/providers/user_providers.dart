import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'app_providers.dart';

// User Info
final userInfoProvider = StreamProvider<UserInfoData?>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUserInfo();
});

// All Goals
final allGoalsProvider = StreamProvider<List<UserGoalData>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchAllGoals();
});

// Goal by Exercise
final goalByExerciseProvider = StreamProvider.family<UserGoalData?, String>((ref, exerciseId) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchGoalByExercise(exerciseId);
});

// All Personal Bests
final allPersonalBestsProvider = StreamProvider<List<UserExercisePBData>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchAllPersonalBests();
});

// Personal Best by Exercise
final personalBestProvider = StreamProvider.family<UserExercisePBData?, String>((ref, exerciseId) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchPersonalBest(exerciseId);
});

// Weekly PR Count
final weeklyPRCountProvider = FutureProvider.family<int, DateTime>((ref, weekStart) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getWeeklyPRCount(weekStart);
});

// User Equipment
final userEquipmentProvider = StreamProvider<List<UserEquipmentData>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUserEquipment();
});

// Theme Mode Provider (from storage)
final themeModeProvider = StateProvider<String>((ref) => 'system');
