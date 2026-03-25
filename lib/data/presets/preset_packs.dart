import 'package:flutter/material.dart';
import '../../models/preset_pack.dart';
import '../../models/enums.dart';

const presetPacks = <PresetPack>[
  // ── 4-Day Split ────────────────────────────────────────────────────────
  PresetPack(
    id: 'four-day-split',
    name: '4-Day Split',
    description: 'Classic muscle-group split hitting each body part once per week.',
    icon: Icons.calendar_view_week_rounded,
    color: Color(0xFF6C63FF),
    routines: [
      PresetRoutine(
        name: 'Chest & Triceps',
        notes: '4-Day Split — Day 1',
        exercises: [
          PresetExercise(exerciseName: 'Flat Chest Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Incline Dumbbell Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Machine Cable Fly', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Skull Crushers', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'Cable Tricep Pushdown', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Cable Tricep Extension', sets: 3, reps: 12),
        ],
      ),
      PresetRoutine(
        name: 'Back & Biceps',
        notes: '4-Day Split — Day 2',
        exercises: [
          PresetExercise(exerciseName: 'Wide Grip Lat Pulldown', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Horizontal Row', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Straight Arm Pulldown', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Incline Bicep Curl', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'EZ Bar Curl', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'Hammer Curl', sets: 3, reps: 10),
        ],
      ),
      PresetRoutine(
        name: 'Shoulders',
        notes: '4-Day Split — Day 3',
        exercises: [
          PresetExercise(exerciseName: 'Dumbbell Shoulder Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Lateral Raise', sets: 4, reps: 12),
          PresetExercise(exerciseName: 'Rear Delt Fly', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Shrugs', sets: 4, reps: 12),
        ],
      ),
      PresetRoutine(
        name: 'Legs',
        notes: '4-Day Split — Day 4',
        exercises: [
          PresetExercise(exerciseName: 'Barbell Squats', sets: 4, reps: 8),
          PresetExercise(exerciseName: 'Leg Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Leg Extension', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Leg Curl', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Calf Raises', sets: 4, reps: 15),
        ],
      ),
    ],
  ),

  // ── Push / Pull / Legs ─────────────────────────────────────────────────
  PresetPack(
    id: 'ppl',
    name: 'Push / Pull / Legs',
    description: 'Popular 3-day split grouping movements by push, pull, and legs.',
    icon: Icons.sync_alt_rounded,
    color: Color(0xFF00BFA5),
    routines: [
      PresetRoutine(
        name: 'Push',
        notes: 'PPL — Chest, Shoulders & Triceps',
        exercises: [
          PresetExercise(exerciseName: 'Flat Chest Press', sets: 4, reps: 8),
          PresetExercise(exerciseName: 'Incline Dumbbell Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Dumbbell Shoulder Press', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'Lateral Raise', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Machine Cable Fly', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Cable Tricep Pushdown', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Cable Tricep Extension', sets: 3, reps: 12),
        ],
      ),
      PresetRoutine(
        name: 'Pull',
        notes: 'PPL — Back, Rear Delts & Biceps',
        exercises: [
          PresetExercise(exerciseName: 'Wide Grip Lat Pulldown', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Horizontal Row', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Straight Arm Pulldown', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Rear Delt Fly', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Shrugs', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'EZ Bar Curl', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'Hammer Curl', sets: 3, reps: 10),
        ],
      ),
      PresetRoutine(
        name: 'Legs',
        notes: 'PPL — Quads, Hamstrings & Calves',
        exercises: [
          PresetExercise(exerciseName: 'Barbell Squats', sets: 4, reps: 8),
          PresetExercise(exerciseName: 'Leg Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Leg Extension', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Leg Curl', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Calf Raises', sets: 4, reps: 15),
        ],
      ),
    ],
  ),

  // ── 5-Day Bro Split ───────────────────────────────────────────────────
  PresetPack(
    id: 'bro-split',
    name: '5-Day Bro Split',
    description: 'Dedicated day for each muscle group with maximum volume.',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFFF6D00),
    routines: [
      PresetRoutine(
        name: 'Chest',
        notes: 'Bro Split — Chest Day',
        exercises: [
          PresetExercise(exerciseName: 'Flat Chest Press', sets: 4, reps: 8),
          PresetExercise(exerciseName: 'Incline Dumbbell Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Chest Press', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'Machine Cable Fly', sets: 3, reps: 12),
        ],
      ),
      PresetRoutine(
        name: 'Back',
        notes: 'Bro Split — Back Day',
        exercises: [
          PresetExercise(exerciseName: 'Wide Grip Lat Pulldown', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Horizontal Row', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Straight Arm Pulldown', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Shrugs', sets: 4, reps: 12),
        ],
      ),
      PresetRoutine(
        name: 'Shoulders',
        notes: 'Bro Split — Shoulder Day',
        exercises: [
          PresetExercise(exerciseName: 'Dumbbell Shoulder Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Lateral Raise', sets: 4, reps: 12),
          PresetExercise(exerciseName: 'Rear Delt Fly', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Machine Shoulder Press', sets: 3, reps: 10),
        ],
      ),
      PresetRoutine(
        name: 'Legs',
        notes: 'Bro Split — Leg Day',
        exercises: [
          PresetExercise(exerciseName: 'Barbell Squats', sets: 4, reps: 8),
          PresetExercise(exerciseName: 'Leg Press', sets: 4, reps: 10),
          PresetExercise(exerciseName: 'Leg Extension', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Leg Curl', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Calf Raises', sets: 4, reps: 15),
        ],
      ),
      PresetRoutine(
        name: 'Arms',
        notes: 'Bro Split — Arms Day (Biceps & Triceps)',
        exercises: [
          PresetExercise(exerciseName: 'Skull Crushers', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'EZ Bar Curl', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'Cable Tricep Pushdown', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Incline Bicep Curl', sets: 3, reps: 10),
          PresetExercise(exerciseName: 'Cable Tricep Extension', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Hammer Curl', sets: 3, reps: 10),
        ],
      ),
    ],
  ),

  // ── Abs ────────────────────────────────────────────────────────────────
  PresetPack(
    id: 'abs',
    name: 'Abs',
    description: 'Core-focused routine — add to any workout day or rest day.',
    icon: Icons.sports_gymnastics_rounded,
    color: Color(0xFFE91E63),
    routines: [
      PresetRoutine(
        name: 'Abs',
        notes: 'Standalone core workout',
        exercises: [
          PresetExercise(exerciseName: 'Cable Crunch', sets: 3, reps: 15),
          PresetExercise(exerciseName: 'Hanging Leg Raise', sets: 3, reps: 12),
          PresetExercise(exerciseName: 'Russian Twist', sets: 3, reps: 20),
          PresetExercise(
            exerciseName: 'Plank',
            sets: 3,
            reps: 0,
            durationSeconds: 60,
            trackingType: TrackingType.duration,
          ),
        ],
      ),
    ],
  ),
];
