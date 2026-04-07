import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../../models/enums.dart';
import '../database/app_database.dart';

class DatabaseSeedService {
  final AppDatabase _database;

  DatabaseSeedService(this._database);

  Future<void> seedExercises() async {
    try {
      final existingExercises = await _database.exerciseDao.getAllExercises();
      if (existingExercises.isNotEmpty) {
        // print('Exercises already seeded (${existingExercises.length} found)');
        return;
      }

      final jsonString = await rootBundle.loadString('assets/exercises.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final exerciseDataList = <ExercisesCompanion>[];
      for (final json in jsonList) {
        try {
          exerciseDataList.add(ExercisesCompanion.insert(
            id: json['id'] ?? '',
            name: json['name'] ?? 'Unknown',
            aliases: _parseStringList(json['aliases']),
            primaryMuscles: _parseMuscleList(json['primary_muscles']),
            secondaryMuscles: _parseMuscleList(json['secondary_muscles']),
            force: Value(_parseForceType(json['force'])),
            level: _parseLevelType(json['level']),
            mechanic: Value(_parseMechanicType(json['mechanic'])),
            equipment: Value(_parseEquipmentType(json['equipment'])),
            category: _parseCategoryType(json['category']),
            instructions: _parseStringList(json['instructions']),
            description: Value(json['description'] as String?),
            tips: _parseStringList(json['tips']),
            image: Value(json['image'] as String?),
          ));
        } catch (e) {
          print('Error parsing exercise "${json['name']}": $e');
        }
      }

      // Insert in batches of 100 for performance
      final batchSize = 100;
      for (var i = 0; i < exerciseDataList.length; i += batchSize) {
        final end = (i + batchSize > exerciseDataList.length) 
            ? exerciseDataList.length 
            : i + batchSize;
        final batch = exerciseDataList.sublist(i, end);
        await _database.batch((b) {
          for (final exercise in batch) {
            b.insert(_database.exercises, exercise, mode: InsertMode.insertOrIgnore);
          }
        });
      }

      // print('Successfully seeded ${exerciseDataList.length} exercises');
    } catch (e, stack) {
      print('Error seeding exercises: $e');
      // print('Stack: $stack');
      rethrow;
    }
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  List<Muscle> _parseMuscleList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value.map((e) {
      final String muscleName = e.toString()
          .replaceAll(' ', '')
          .replaceAll('_', '');
      return Muscle.values.firstWhere(
        (m) => m.name.toLowerCase() == muscleName.toLowerCase(),
        orElse: () {
          final normalized = e.toString().toLowerCase().replaceAll(' ', '');
          return Muscle.values.firstWhere(
            (m) => m.name.toLowerCase() == normalized,
            orElse: () => Muscle.chest,
          );
        },
      );
    }).toList();
  }

  CategoryType _parseCategoryType(dynamic value) {
    if (value == null) return CategoryType.strength;
    final s = value.toString().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    const mapping = {
      'strength': CategoryType.strength,
      'stretching': CategoryType.stretching,
      'plyometrics': CategoryType.plyometrics,
      'strongman': CategoryType.strongman,
      'powerlifting': CategoryType.powerlifting,
      'cardio': CategoryType.cardio,
      'olympicweightlifting': CategoryType.olympicWeightlifting,
      'olympic_weightlifting': CategoryType.olympicWeightlifting,
    };
    return mapping[s] ?? CategoryType.strength;
  }

  ForceType? _parseForceType(dynamic value) {
    if (value == null) return null;
    final s = value.toString().toLowerCase();
    const mapping = {
      'pull': ForceType.pull,
      'push': ForceType.push,
      'static': ForceType.static,
    };
    return mapping[s];
  }

  LevelType _parseLevelType(dynamic value) {
    if (value == null) return LevelType.beginner;
    final s = value.toString().toLowerCase();
    const mapping = {
      'beginner': LevelType.beginner,
      'intermediate': LevelType.intermediate,
      'expert': LevelType.expert,
    };
    return mapping[s] ?? LevelType.beginner;
  }

  MechanicType? _parseMechanicType(dynamic value) {
    if (value == null) return null;
    final s = value.toString().toLowerCase();
    const mapping = {
      'compound': MechanicType.compound,
      'isolation': MechanicType.isolation,
    };
    return mapping[s];
  }

  EquipmentType? _parseEquipmentType(dynamic value) {
    if (value == null) return null;
    final s = value.toString().toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');
    const mapping = {
      'bodyonly': EquipmentType.bodyOnly,
      'machine': EquipmentType.machine,
      'other': EquipmentType.other,
      'foamroll': EquipmentType.foamRoll,
      'kettlebells': EquipmentType.kettlebells,
      'dumbbell': EquipmentType.dumbbell,
      'cable': EquipmentType.cable,
      'barbell': EquipmentType.barbell,
      'bands': EquipmentType.bands,
      'medicineball': EquipmentType.medicineBall,
      'exerciseball': EquipmentType.exerciseBall,
      'ezcurlbar': EquipmentType.ezCurlBar,
    };
    return mapping[s] ?? EquipmentType.other;
  }
}
