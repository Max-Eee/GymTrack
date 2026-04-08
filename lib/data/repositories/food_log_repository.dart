import '../database/app_database.dart';
import '../database/daos/food_log_dao.dart';

class FoodLogRepository {
  final FoodLogDao _foodLogDao;

  FoodLogRepository(this._foodLogDao);

  Future<int> insertFoodLog(FoodLogsCompanion entry) =>
      _foodLogDao.insertFoodLog(entry);

  Future<int> deleteFoodLog(String id) =>
      _foodLogDao.deleteFoodLog(id);

  Future<int> updateFoodLog(FoodLogsCompanion entry) =>
      _foodLogDao.updateFoodLog(entry);

  Stream<List<FoodLogData>> watchFoodLogsByDate(DateTime date) =>
      _foodLogDao.watchFoodLogsByDate(date);

  Stream<List<FoodLogData>> watchTodayFoodLogs() =>
      _foodLogDao.watchTodayFoodLogs();

  Future<List<FoodLogData>> getFoodLogsByDate(DateTime date) =>
      _foodLogDao.getFoodLogsByDate(date);
}
