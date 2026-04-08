import 'package:drift/drift.dart' as drift;
import '../../models/enums.dart';
import '../database/app_database.dart';
import 'package:uuid/uuid.dart';

class CustomExerciseAdder {
  final AppDatabase _database;
  final _uuid = const Uuid();

  CustomExerciseAdder(this._database);

  Future<void> addCustomExercises() async {
    // First, get all existing exercise names to avoid duplicates
    final allExisting = await _database.exerciseDao.getAllExercises();
    final existingNames = allExisting.map((e) => e.name.toLowerCase().trim()).toSet();

    final exercisesToAdd = [
      // Chest
      _createExercise(
        name: 'Chest Press',
        primaryMuscles: [Muscle.chest],
        secondaryMuscles: [Muscle.shoulders, Muscle.triceps],
        category: CategoryType.strength,
        equipment: EquipmentType.machine,
        force: ForceType.push,
        mechanic: MechanicType.compound,
        level: LevelType.beginner,
        instructions: ['Sit on the machine with back against pad', 'Grasp handles at chest level', 'Push handles forward until arms are extended', 'Slowly return to starting position'],
        tips: ['Keep your back flat against the pad', 'Don\'t lock out elbows completely'],
      ),
      _createExercise(
        name: 'Flat Chest Press',
        primaryMuscles: [Muscle.chest],
        secondaryMuscles: [Muscle.shoulders, Muscle.triceps],
        category: CategoryType.strength,
        equipment: EquipmentType.barbell,
        force: ForceType.push,
        mechanic: MechanicType.compound,
        level: LevelType.beginner,
        instructions: ['Lie flat on bench', 'Grip bar slightly wider than shoulder width', 'Lower bar to mid-chest', 'Press back to starting position'],
        tips: ['Keep feet flat on floor', 'Maintain natural arch in lower back'],
      ),
      _createExercise(
        name: 'Machine Cable Fly',
        primaryMuscles: [Muscle.chest],
        secondaryMuscles: [Muscle.shoulders],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.push,
        mechanic: MechanicType.isolation,
        level: LevelType.intermediate,
        instructions: ['Stand centered between cables', 'Grab handles with arms extended', 'Bring hands together in front of chest', 'Slowly return to starting position'],
        tips: ['Keep a slight bend in elbows', 'Focus on squeezing chest at peak contraction'],
      ),
      _createExercise(
        name: 'Incline Cable Fly',
        primaryMuscles: [Muscle.chest],
        secondaryMuscles: [Muscle.shoulders],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.push,
        mechanic: MechanicType.isolation,
        level: LevelType.intermediate,
        instructions: ['Set bench to 30-45 degree angle', 'Position between low cables', 'Bring cables up and together', 'Control the descent'],
        tips: ['Targets upper chest', 'Don\'t use momentum'],
      ),
      _createExercise(
        name: 'Decline Cable Fly',
        primaryMuscles: [Muscle.chest],
        secondaryMuscles: [],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.push,
        mechanic: MechanicType.isolation,
        level: LevelType.intermediate,
        instructions: ['Set bench to decline angle', 'Position between high cables', 'Bring cables down and together', 'Control the return'],
        tips: ['Targets lower chest', 'Maintain constant tension'],
      ),
      
      // Triceps
      _createExercise(
        name: 'Cable Tricep Pushdown',
        primaryMuscles: [Muscle.triceps],
        secondaryMuscles: [Muscle.shoulders],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.push,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Stand facing cable machine', 'Grip bar with overhand grip', 'Push bar down until arms fully extended', 'Return to starting position'],
        tips: ['Keep elbows tucked at sides', 'Don\'t use body momentum'],
      ),
      _createExercise(
        name: 'Cable Tricep Extension',
        primaryMuscles: [Muscle.triceps],
        secondaryMuscles: [],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.push,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Face away from cable machine', 'Hold rope attachment overhead', 'Extend arms forward', 'Return with control'],
        tips: ['Keep upper arms stationary', 'Full extension for maximum contraction'],
      ),
      _createExercise(
        name: 'Skull Crushers',
        primaryMuscles: [Muscle.triceps],
        secondaryMuscles: [],
        category: CategoryType.strength,
        equipment: EquipmentType.barbell,
        force: ForceType.push,
        mechanic: MechanicType.isolation,
        level: LevelType.intermediate,
        instructions: ['Lie on bench with bar extended over chest', 'Lower bar to forehead by bending elbows', 'Extend arms back to start', 'Keep upper arms stationary'],
        tips: ['Use EZ bar for wrist comfort', 'Don\'t go too heavy'],
      ),
      
      // Back
      _createExercise(
        name: 'Wide Grip Lat Pulldown',
        primaryMuscles: [Muscle.lats],
        secondaryMuscles: [Muscle.biceps, Muscle.middleBack],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.pull,
        mechanic: MechanicType.compound,
        level: LevelType.beginner,
        instructions: ['Sit at machine with wide grip on bar', 'Pull bar down to upper chest', 'Squeeze shoulder blades together', 'Return with control'],
        tips: ['Lean back slightly', 'Focus on pulling with back, not arms'],
      ),
      _createExercise(
        name: 'Horizontal Row',
        primaryMuscles: [Muscle.middleBack],
        secondaryMuscles: [Muscle.biceps, Muscle.lats, Muscle.shoulders],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.pull,
        mechanic: MechanicType.compound,
        level: LevelType.beginner,
        instructions: ['Sit at cable row machine', 'Pull handle to abdomen', 'Keep back straight', 'Squeeze shoulder blades'],
        tips: ['Don\'t use momentum', 'Keep chest up'],
      ),
      _createExercise(
        name: 'Straight Arm Pulldown',
        primaryMuscles: [Muscle.lats],
        secondaryMuscles: [Muscle.shoulders],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.intermediate,
        instructions: ['Stand facing cable machine', 'Hold bar with straight arms', 'Pull bar down to thighs', 'Keep arms straight throughout'],
        tips: ['Slight bend in elbows only', 'Feel the stretch in lats'],
      ),
      _createExercise(
        name: 'Wide Grip Horizontal Row',
        primaryMuscles: [Muscle.middleBack],
        secondaryMuscles: [Muscle.biceps, Muscle.lats, Muscle.shoulders],
        category: CategoryType.strength,
        equipment: EquipmentType.cable,
        force: ForceType.pull,
        mechanic: MechanicType.compound,
        level: LevelType.intermediate,
        instructions: ['Sit at cable machine with wide grip attachment', 'Pull to upper abdomen', 'Focus on upper back contraction', 'Control the negative'],
        tips: ['Wider grip targets upper back more', 'Keep torso stable'],
      ),
      
      // Biceps
      _createExercise(
        name: 'EZ Bar Curl',
        primaryMuscles: [Muscle.biceps],
        secondaryMuscles: [Muscle.forearms],
        category: CategoryType.strength,
        equipment: EquipmentType.ezCurlBar,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Stand holding EZ bar with underhand grip', 'Curl bar up to shoulders', 'Keep elbows tucked', 'Lower with control'],
        tips: ['EZ bar reduces wrist strain', 'Don\'t swing the weight'],
      ),
      _createExercise(
        name: 'Hammer Curl',
        primaryMuscles: [Muscle.biceps],
        secondaryMuscles: [Muscle.forearms],
        category: CategoryType.strength,
        equipment: EquipmentType.dumbbell,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Hold dumbbells with neutral grip (palms facing)', 'Curl up keeping palms facing each other', 'Lower with control', 'Alternate or do both together'],
        tips: ['Targets brachialis and forearms', 'Keep wrists neutral'],
      ),
      _createExercise(
        name: 'Bicep Curl',
        primaryMuscles: [Muscle.biceps],
        secondaryMuscles: [Muscle.forearms],
        category: CategoryType.strength,
        equipment: EquipmentType.dumbbell,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Hold dumbbells at sides with palms forward', 'Curl up to shoulders', 'Keep upper arms still', 'Lower slowly'],
        tips: ['Can do alternating or together', 'Full range of motion'],
      ),
      _createExercise(
        name: 'Incline Bicep Curl',
        primaryMuscles: [Muscle.biceps],
        secondaryMuscles: [Muscle.forearms],
        category: CategoryType.strength,
        equipment: EquipmentType.dumbbell,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.intermediate,
        instructions: ['Sit on incline bench (45 degrees)', 'Let arms hang straight down', 'Curl dumbbells up', 'Get full stretch at bottom'],
        tips: ['Greater range of motion', 'Targets long head of biceps'],
      ),
      
      // Shoulders
      _createExercise(
        name: 'Dumbbell Shoulder Press',
        primaryMuscles: [Muscle.shoulders],
        secondaryMuscles: [Muscle.triceps],
        category: CategoryType.strength,
        equipment: EquipmentType.dumbbell,
        force: ForceType.push,
        mechanic: MechanicType.compound,
        level: LevelType.beginner,
        instructions: ['Sit on bench with back support', 'Hold dumbbells at shoulder height', 'Press up until arms extended', 'Lower with control'],
        tips: ['Don\'t lock out elbows', 'Keep core engaged'],
      ),
      _createExercise(
        name: 'Machine Shoulder Press',
        primaryMuscles: [Muscle.shoulders],
        secondaryMuscles: [Muscle.triceps],
        category: CategoryType.strength,
        equipment: EquipmentType.machine,
        force: ForceType.push,
        mechanic: MechanicType.compound,
        level: LevelType.beginner,
        instructions: ['Adjust seat height', 'Grip handles at shoulder level', 'Press up until arms extended', 'Lower slowly'],
        tips: ['Good for beginners', 'Stable movement path'],
      ),
      _createExercise(
        name: 'Lateral Raise',
        primaryMuscles: [Muscle.shoulders],
        secondaryMuscles: [],
        category: CategoryType.strength,
        equipment: EquipmentType.dumbbell,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Stand with dumbbells at sides', 'Raise arms out to sides', 'Stop at shoulder height', 'Lower slowly'],
        tips: ['Slight bend in elbows', 'Don\'t use momentum', 'Targets side delts'],
      ),
      _createExercise(
        name: 'Rear Delt Fly',
        primaryMuscles: [Muscle.shoulders],
        secondaryMuscles: [Muscle.middleBack],
        category: CategoryType.strength,
        equipment: EquipmentType.dumbbell,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.intermediate,
        instructions: ['Bend over at waist with dumbbells', 'Raise arms out to sides', 'Squeeze shoulder blades', 'Lower with control'],
        tips: ['Keep back straight', 'Targets rear delts'],
      ),
      _createExercise(
        name: 'Shrugs',
        primaryMuscles: [Muscle.traps],
        secondaryMuscles: [],
        category: CategoryType.strength,
        equipment: EquipmentType.dumbbell,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Hold dumbbells at sides', 'Raise shoulders straight up', 'Hold briefly at top', 'Lower slowly'],
        tips: ['Don\'t roll shoulders', 'Straight up and down motion'],
      ),
      
      // Legs
      _createExercise(
        name: 'Barbell Squats',
        primaryMuscles: [Muscle.quadriceps],
        secondaryMuscles: [Muscle.hamstrings, Muscle.glutes, Muscle.lowerBack],
        category: CategoryType.strength,
        equipment: EquipmentType.barbell,
        force: ForceType.push,
        mechanic: MechanicType.compound,
        level: LevelType.intermediate,
        instructions: ['Bar on upper back', 'Feet shoulder width apart', 'Squat down until thighs parallel', 'Push through heels to stand'],
        tips: ['Keep chest up', 'Knees track over toes', 'Core tight'],
      ),
      _createExercise(
        name: 'Leg Press',
        primaryMuscles: [Muscle.quadriceps],
        secondaryMuscles: [Muscle.hamstrings, Muscle.glutes],
        category: CategoryType.strength,
        equipment: EquipmentType.machine,
        force: ForceType.push,
        mechanic: MechanicType.compound,
        level: LevelType.beginner,
        instructions: ['Sit in machine with feet on platform', 'Lower weight by bending knees', 'Push back to starting position', 'Don\'t lock knees'],
        tips: ['Keep lower back pressed into pad', 'Full range of motion'],
      ),
      _createExercise(
        name: 'Leg Extension',
        primaryMuscles: [Muscle.quadriceps],
        secondaryMuscles: [],
        category: CategoryType.strength,
        equipment: EquipmentType.machine,
        force: ForceType.push,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Sit in machine with pad against shins', 'Extend legs until straight', 'Squeeze quads at top', 'Lower with control'],
        tips: ['Adjust pad position', 'Don\'t use momentum'],
      ),
      _createExercise(
        name: 'Leg Curl',
        primaryMuscles: [Muscle.hamstrings],
        secondaryMuscles: [Muscle.calves],
        category: CategoryType.strength,
        equipment: EquipmentType.machine,
        force: ForceType.pull,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Lie face down on machine', 'Pad against back of ankles', 'Curl legs up toward glutes', 'Lower slowly'],
        tips: ['Keep hips down', 'Full contraction at top'],
      ),
      _createExercise(
        name: 'Calf Raises',
        primaryMuscles: [Muscle.calves],
        secondaryMuscles: [],
        category: CategoryType.strength,
        equipment: EquipmentType.machine,
        force: ForceType.push,
        mechanic: MechanicType.isolation,
        level: LevelType.beginner,
        instructions: ['Stand on machine with balls of feet on edge', 'Lower heels below platform', 'Push up onto toes', 'Hold briefly at top'],
        tips: ['Full range of motion', 'Pause at peak contraction'],
      ),
    ];

    int addedCount = 0;
    int skippedCount = 0;

    for (final exercise in exercisesToAdd) {
      try {
        final name = exercise.name.value;
        final normalizedName = name.toLowerCase().trim();
        
        // Check against existing names
        if (existingNames.contains(normalizedName)) {
          skippedCount++;
          // print('○ Skipped (exists): $name');
        } else {
          await _database.exerciseDao.insertExercise(exercise);
          addedCount++;
          // print('✓ Added: $name');
        }
      } catch (e) {
        print('✗ Error adding exercise: $e');
      }
    }

    // print('\n=================================');
    // print('Added: $addedCount exercises');
    // print('Skipped: $skippedCount exercises');
    // print('=================================\n');
  }

  ExercisesCompanion _createExercise({
    required String name,
    required List<Muscle> primaryMuscles,
    List<Muscle> secondaryMuscles = const [],
    required CategoryType category,
    EquipmentType? equipment,
    ForceType? force,
    MechanicType? mechanic,
    required LevelType level,
    List<String> instructions = const [],
    List<String> tips = const [],
  }) {
    return ExercisesCompanion.insert(
      id: _uuid.v4(),
      name: name,
      aliases: const <String>[],
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      force: drift.Value(force),
      level: level,
      mechanic: drift.Value(mechanic),
      equipment: drift.Value(equipment),
      category: category,
      instructions: instructions,
      description: const drift.Value(null),
      tips: tips,
      image: const drift.Value(null),
      isCustom: const drift.Value(false),
    );
  }
}
