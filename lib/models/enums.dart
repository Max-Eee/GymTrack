enum TrackingType {
  reps,
  duration,
}

enum CategoryType {
  strength,
  stretching,
  plyometrics,
  strongman,
  powerlifting,
  cardio,
  olympicWeightlifting,
}

enum EquipmentType {
  bodyOnly,
  machine,
  other,
  foamRoll,
  kettlebells,
  dumbbell,
  cable,
  barbell,
  bands,
  medicineBall,
  exerciseBall,
  ezCurlBar,
}

enum ForceType {
  pull,
  push,
  static,
}

enum LevelType {
  beginner,
  intermediate,
  expert,
}

enum MechanicType {
  compound,
  isolation,
}

enum Muscle {
  abdominals,
  hamstrings,
  adductors,
  quadriceps,
  biceps,
  shoulders,
  chest,
  middleBack,
  calves,
  glutes,
  lowerBack,
  lats,
  triceps,
  traps,
  forearms,
  neck,
  abductors,
}

enum GoalType {
  weight,
}

extension CategoryTypeExtension on CategoryType {
  String get displayName {
    switch (this) {
      case CategoryType.strength:
        return 'Strength';
      case CategoryType.stretching:
        return 'Stretching';
      case CategoryType.plyometrics:
        return 'Plyometrics';
      case CategoryType.strongman:
        return 'Strongman';
      case CategoryType.powerlifting:
        return 'Powerlifting';
      case CategoryType.cardio:
        return 'Cardio';
      case CategoryType.olympicWeightlifting:
        return 'Olympic Weightlifting';
    }
  }
}

extension EquipmentTypeExtension on EquipmentType {
  String get displayName {
    switch (this) {
      case EquipmentType.bodyOnly:
        return 'Body Only';
      case EquipmentType.machine:
        return 'Machine';
      case EquipmentType.other:
        return 'Other';
      case EquipmentType.foamRoll:
        return 'Foam Roll';
      case EquipmentType.kettlebells:
        return 'Kettlebells';
      case EquipmentType.dumbbell:
        return 'Dumbbell';
      case EquipmentType.cable:
        return 'Cable';
      case EquipmentType.barbell:
        return 'Barbell';
      case EquipmentType.bands:
        return 'Bands';
      case EquipmentType.medicineBall:
        return 'Medicine Ball';
      case EquipmentType.exerciseBall:
        return 'Exercise Ball';
      case EquipmentType.ezCurlBar:
        return 'E-Z Curl Bar';
    }
  }
}

extension ForceTypeExtension on ForceType {
  String get displayName {
    switch (this) {
      case ForceType.pull:
        return 'Pull';
      case ForceType.push:
        return 'Push';
      case ForceType.static:
        return 'Static';
    }
  }
}

extension LevelTypeExtension on LevelType {
  String get displayName {
    switch (this) {
      case LevelType.beginner:
        return 'Beginner';
      case LevelType.intermediate:
        return 'Intermediate';
      case LevelType.expert:
        return 'Expert';
    }
  }
}

extension MechanicTypeExtension on MechanicType {
  String get displayName {
    switch (this) {
      case MechanicType.compound:
        return 'Compound';
      case MechanicType.isolation:
        return 'Isolation';
    }
  }
}

extension MuscleExtension on Muscle {
  String get displayName {
    switch (this) {
      case Muscle.abdominals:
        return 'Abdominals';
      case Muscle.hamstrings:
        return 'Hamstrings';
      case Muscle.adductors:
        return 'Adductors';
      case Muscle.quadriceps:
        return 'Quadriceps';
      case Muscle.biceps:
        return 'Biceps';
      case Muscle.shoulders:
        return 'Shoulders';
      case Muscle.chest:
        return 'Chest';
      case Muscle.middleBack:
        return 'Middle Back';
      case Muscle.calves:
        return 'Calves';
      case Muscle.glutes:
        return 'Glutes';
      case Muscle.lowerBack:
        return 'Lower Back';
      case Muscle.lats:
        return 'Lats';
      case Muscle.triceps:
        return 'Triceps';
      case Muscle.traps:
        return 'Traps';
      case Muscle.forearms:
        return 'Forearms';
      case Muscle.neck:
        return 'Neck';
      case Muscle.abductors:
        return 'Abductors';
    }
  }
}
