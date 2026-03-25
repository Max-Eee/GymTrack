import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../models/enums.dart';
import 'tables/app_tables.dart';
import 'daos/exercise_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/user_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    FavouriteExercises,
    WorkoutPlans,
    WorkoutPlanExercises,
    WorkoutLogs,
    WorkoutLogExercises,
    SetLogs,
    UserExercisePBs,
    UserGoals,
    UserInfos,
    UserEquipments,
  ],
  daos: [
    ExerciseDao,
    WorkoutDao,
    UserDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(exercises, exercises.isCustom);
        }
        if (from < 3) {
          await m.addColumn(userInfos, userInfos.name);
          await m.addColumn(userInfos, userInfos.avatarPath);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gymtrack.db'));
    return NativeDatabase(file);
  });
}
