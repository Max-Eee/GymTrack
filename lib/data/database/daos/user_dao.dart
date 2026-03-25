import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';
import '../../../models/enums.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [UserInfos, UserGoals, UserExercisePBs, UserEquipments])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  // User Info
  Stream<UserInfoData?> watchUserInfo() {
    return select(userInfos).watchSingleOrNull();
  }

  Future<UserInfoData?> getUserInfo() async {
    final results = await select(userInfos).get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertOrUpdateUserInfo(UserInfosCompanion userInfo) {
    return into(userInfos).insert(userInfo, mode: InsertMode.insertOrReplace);
  }

  // User Goals
  Stream<List<UserGoalData>> watchAllGoals() {
    return (select(userGoals)
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  Future<List<UserGoalData>> getAllGoals() {
    return (select(userGoals)
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .get();
  }

  Stream<UserGoalData?> watchGoalByExercise(String exerciseId) {
    return (select(userGoals)..where((g) => g.exerciseId.equals(exerciseId)))
        .watchSingleOrNull();
  }

  Future<UserGoalData?> getGoalByExercise(String exerciseId) {
    return (select(userGoals)..where((g) => g.exerciseId.equals(exerciseId)))
        .getSingleOrNull();
  }

  Future<int> insertGoal(UserGoalsCompanion goal) {
    return into(userGoals).insert(goal);
  }

  Future<bool> updateGoal(UserGoalData goal) {
    return update(userGoals).replace(goal);
  }

  Future<int> deleteGoal(String id) {
    return (delete(userGoals)..where((g) => g.id.equals(id))).go();
  }

  // Personal Bests
  Stream<List<UserExercisePBData>> watchAllPersonalBests() {
    return select(userExercisePBs).watch();
  }

  Future<List<UserExercisePBData>> getAllPersonalBests() {
    return select(userExercisePBs).get();
  }

  Stream<UserExercisePBData?> watchPersonalBest(String exerciseId) {
    return (select(userExercisePBs)..where((pb) => pb.exerciseId.equals(exerciseId)))
        .watchSingleOrNull();
  }

  Future<UserExercisePBData?> getPersonalBest(String exerciseId) {
    return (select(userExercisePBs)..where((pb) => pb.exerciseId.equals(exerciseId)))
        .getSingleOrNull();
  }

  Future<int> insertOrUpdatePersonalBest(UserExercisePBsCompanion pb) {
    return into(userExercisePBs).insert(pb, mode: InsertMode.insertOrReplace);
  }

  Future<bool> checkAndUpdatePR({
    required String exerciseId,
    required double weight,
    int? reps,
    int? exerciseDuration,
    String? workoutLogId,
  }) async {
    final currentPB = await getPersonalBest(exerciseId);

    bool isNewPR = false;
    if (currentPB == null || weight > currentPB.weight) {
      isNewPR = true;
    } else if (weight == currentPB.weight) {
      if (reps != null && currentPB.reps != null && reps > currentPB.reps!) {
        isNewPR = true;
      }
    }

    if (isNewPR) {
      await insertOrUpdatePersonalBest(
        UserExercisePBsCompanion.insert(
          exerciseId: exerciseId,
          weight: weight,
          reps: Value(reps),
          exerciseDuration: Value(exerciseDuration),
          workoutLogId: Value(workoutLogId),
        ),
      );
    }

    return isNewPR;
  }

  Future<int> getWeeklyPRCount(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    final count = userExercisePBs.exerciseId.count();
    final query = selectOnly(userExercisePBs)
      ..addColumns([count])
      ..where(userExercisePBs.createdAt.isBiggerOrEqualValue(weekStart) &
              userExercisePBs.createdAt.isSmallerOrEqualValue(weekEnd));
    
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // User Equipment
  Stream<List<UserEquipmentData>> watchUserEquipment() {
    return select(userEquipments).watch();
  }

  Future<List<UserEquipmentData>> getUserEquipment() {
    return select(userEquipments).get();
  }

  Future<void> setUserEquipment(List<EquipmentType> equipment) async {
      await transaction(() async {
      await delete(userEquipments).go();
      await batch((batch) {
        for (final eq in equipment) {
          batch.insert(
            userEquipments,
            UserEquipmentsCompanion.insert(equipmentType: Value(eq)),
          );
        }
      });
    });
  }

  Future<bool> hasEquipment(EquipmentType equipment) async {
    final result = await (select(userEquipments)
          ..where((e) => e.equipmentType.equalsValue(equipment)))
        .getSingleOrNull();
    return result != null;
  }
}
