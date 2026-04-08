import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';
import '../../../models/enums.dart';

part 'food_log_dao.g.dart';

@DriftAccessor(tables: [FoodLogs])
class FoodLogDao extends DatabaseAccessor<AppDatabase> with _$FoodLogDaoMixin {
  FoodLogDao(AppDatabase db) : super(db);

  Future<int> insertFoodLog(FoodLogsCompanion entry) {
    return into(foodLogs).insert(entry);
  }

  Future<int> deleteFoodLog(String id) {
    return (delete(foodLogs)..where((f) => f.id.equals(id))).go();
  }

  Future<int> updateFoodLog(FoodLogsCompanion entry) {
    return (update(foodLogs)..where((f) => f.id.equals(entry.id.value))).write(entry);
  }

  Stream<List<FoodLogData>> watchFoodLogsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodLogs)
          ..where((f) => f.loggedAt.isBiggerOrEqualValue(start) & f.loggedAt.isSmallerThanValue(end))
          ..orderBy([(f) => OrderingTerm.desc(f.loggedAt)]))
        .watch();
  }

  Stream<List<FoodLogData>> watchTodayFoodLogs() {
    return watchFoodLogsByDate(DateTime.now());
  }

  Future<List<FoodLogData>> getFoodLogsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodLogs)
          ..where((f) => f.loggedAt.isBiggerOrEqualValue(start) & f.loggedAt.isSmallerThanValue(end))
          ..orderBy([(f) => OrderingTerm.desc(f.loggedAt)]))
        .get();
  }
}
