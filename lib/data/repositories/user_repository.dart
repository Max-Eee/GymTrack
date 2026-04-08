import '../database/app_database.dart';
import '../database/daos/user_dao.dart';
import '../../models/enums.dart';

class UserRepository {
  final UserDao _userDao;

  UserRepository(this._userDao);

  // User Info
  Stream<UserInfoData?> watchUserInfo() => _userDao.watchUserInfo();
  
  Future<UserInfoData?> getUserInfo() => _userDao.getUserInfo();
  
  Future<int> insertOrUpdateUserInfo(UserInfosCompanion userInfo) => 
      _userDao.insertOrUpdateUserInfo(userInfo);

  // Goals
  Stream<List<UserGoalData>> watchAllGoals() => _userDao.watchAllGoals();
  
  Stream<UserGoalData?> watchGoalByExercise(String exerciseId) => 
      _userDao.watchGoalByExercise(exerciseId);
  
  Future<List<UserGoalData>> getAllGoals() => _userDao.getAllGoals();
  
  Future<UserGoalData?> getGoalByExercise(String exerciseId) => 
      _userDao.getGoalByExercise(exerciseId);
  
  Future<int> insertGoal(UserGoalsCompanion goal) => _userDao.insertGoal(goal);
  
  Future<bool> updateGoal(UserGoalData goal) => _userDao.updateGoal(goal);
  
  Future<int> deleteGoal(String id) => _userDao.deleteGoal(id);

  // Personal Bests
  Stream<List<UserExercisePBData>> watchAllPersonalBests() => 
      _userDao.watchAllPersonalBests();
  
  Stream<UserExercisePBData?> watchPersonalBest(String exerciseId) => 
      _userDao.watchPersonalBest(exerciseId);
  
  Future<List<UserExercisePBData>> getAllPersonalBests() => 
      _userDao.getAllPersonalBests();
  
  Future<UserExercisePBData?> getPersonalBest(String exerciseId) => 
      _userDao.getPersonalBest(exerciseId);
  
  Future<int> insertOrUpdatePersonalBest(UserExercisePBsCompanion pb) => 
      _userDao.insertOrUpdatePersonalBest(pb);
  
  Future<bool> checkAndUpdatePR({
    required String exerciseId,
    required double weight,
    int? reps,
    int? exerciseDuration,
    String? workoutLogId,
  }) => _userDao.checkAndUpdatePR(
        exerciseId: exerciseId,
        weight: weight,
        reps: reps,
        exerciseDuration: exerciseDuration,
        workoutLogId: workoutLogId,
      );
  
  Future<int> getWeeklyPRCount(DateTime weekStart) => 
      _userDao.getWeeklyPRCount(weekStart);

  // Equipment
  Stream<List<UserEquipmentData>> watchUserEquipment() => 
      _userDao.watchUserEquipment();
  
  Future<List<UserEquipmentData>> getUserEquipment() => 
      _userDao.getUserEquipment();
  
  Future<void> setUserEquipment(List<EquipmentType> equipment) => 
      _userDao.setUserEquipment(equipment);
  
  Future<bool> hasEquipment(EquipmentType equipment) => 
      _userDao.hasEquipment(equipment);
}
