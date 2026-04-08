import 'package:flutter/material.dart';
import 'enums.dart';

class PresetExercise {
  final String exerciseName;
  final int sets;
  final int reps;
  final int? durationSeconds;
  final TrackingType trackingType;

  const PresetExercise({
    required this.exerciseName,
    this.sets = 3,
    this.reps = 10,
    this.durationSeconds,
    this.trackingType = TrackingType.reps,
  });
}

class PresetRoutine {
  final String name;
  final String? notes;
  final List<PresetExercise> exercises;

  const PresetRoutine({
    required this.name,
    this.notes,
    required this.exercises,
  });

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);
}

class PresetPack {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<PresetRoutine> routines;

  const PresetPack({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.routines,
  });

  int get totalExercises =>
      routines.fold(0, (sum, r) => sum + r.exercises.length);
}
