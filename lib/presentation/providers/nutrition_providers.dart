import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/food_log_repository.dart';
import '../../services/nutrition_service.dart';
import '../../services/gemma_model_service.dart';
import 'app_providers.dart';

final foodLogRepositoryProvider = Provider<FoodLogRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FoodLogRepository(db.foodLogDao);
});

final nutritionServiceProvider = Provider<NutritionService>((ref) {
  final gemma = ref.watch(gemmaModelServiceProvider);
  return NutritionService(gemma);
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final foodLogsByDateProvider = StreamProvider.family<List<FoodLogData>, DateTime>((ref, date) {
  final repo = ref.watch(foodLogRepositoryProvider);
  return repo.watchFoodLogsByDate(date);
});

final todayFoodLogsProvider = StreamProvider<List<FoodLogData>>((ref) {
  final repo = ref.watch(foodLogRepositoryProvider);
  return repo.watchTodayFoodLogs();
});
