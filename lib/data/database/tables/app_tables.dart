import 'package:drift/drift.dart';
import '../../../models/enums.dart';

@DataClassName('ExerciseData')
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get aliases => text().map(const StringListConverter())();
  TextColumn get primaryMuscles => text().map(const MuscleListConverter())();
  TextColumn get secondaryMuscles => text().map(const MuscleListConverter())();
  IntColumn get force => intEnum<ForceType>().nullable()();
  IntColumn get level => intEnum<LevelType>()();
  IntColumn get mechanic => intEnum<MechanicType>().nullable()();
  IntColumn get equipment => intEnum<EquipmentType>().nullable()();
  IntColumn get category => intEnum<CategoryType>()();
  TextColumn get instructions => text().map(const StringListConverter())();
  TextColumn get description => text().nullable()();
  TextColumn get tips => text().map(const StringListConverter())();
  TextColumn get image => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dateCreated => dateTime().nullable()();
  DateTimeColumn get dateUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FavouriteExerciseData')
class FavouriteExercises extends Table {
  TextColumn get exerciseId => text().references(Exercises, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get favouritedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

@DataClassName('WorkoutPlanData')
class WorkoutPlans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSystemRoutine => boolean().withDefault(const Constant(false))();
  TextColumn get systemRoutineCategory => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutPlanExerciseData')
class WorkoutPlanExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutPlanId => text().references(WorkoutPlans, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sets => integer()();
  IntColumn get reps => integer().nullable()();
  IntColumn get exerciseDuration => integer().nullable()();
  IntColumn get order => integer().nullable()();
  IntColumn get trackingType => intEnum<TrackingType>()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutLogData')
class WorkoutLogs extends Table {
  TextColumn get id => text()();
  TextColumn get workoutPlanId => text().references(WorkoutPlans, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  IntColumn get duration => integer()();
  BoolColumn get inProgress => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dateUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutLogExerciseData')
class WorkoutLogExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutLogId => text().references(WorkoutLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get trackingType => intEnum<TrackingType>()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SetLogData')
class SetLogs extends Table {
  TextColumn get id => text()();
  TextColumn get workoutLogExerciseId => text().references(WorkoutLogExercises, #id, onDelete: KeyAction.cascade)();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get exerciseDuration => integer().nullable()();
  IntColumn get order => integer().nullable()();
  BoolColumn get isWarmUp => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserExercisePBData')
class UserExercisePBs extends Table {
  TextColumn get exerciseId => text().references(Exercises, #id)();
  RealColumn get weight => real()();
  IntColumn get reps => integer().nullable()();
  IntColumn get exerciseDuration => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get workoutLogId => text().nullable().references(WorkoutLogs, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

@DataClassName('UserGoalData')
class UserGoals extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get goalType => intEnum<GoalType>()();
  RealColumn get goalValue => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserInfoData')
class UserInfos extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get avatarPath => text().withDefault(const Constant(''))();
  IntColumn get age => integer().nullable()();
  RealColumn get height => real().nullable()();
  RealColumn get weight => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserEquipmentData')
class UserEquipments extends Table {
  IntColumn get equipmentType => intEnum<EquipmentType>()();

  @override
  Set<Column> get primaryKey => {equipmentType};
}

@DataClassName('FoodLogData')
class FoodLogs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get calories => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();
  RealColumn get fiberG => real().nullable()();
  TextColumn get servingSize => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  IntColumn get mealType => intEnum<MealType>()();

  @override
  Set<Column> get primaryKey => {id};
}

// Converters for list types
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',');
  }

  @override
  String toSql(List<String> value) {
    return value.join(',');
  }
}

class MuscleListConverter extends TypeConverter<List<Muscle>, String> {
  const MuscleListConverter();

  @override
  List<Muscle> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',').map((e) => Muscle.values.firstWhere(
      (m) => m.name == e,
      orElse: () => Muscle.chest,
    )).toList();
  }

  @override
  String toSql(List<Muscle> value) {
    return value.map((e) => e.name).join(',');
  }
}
