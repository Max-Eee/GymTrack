import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    @Default([]) List<String> aliases,
    @Default([]) List<Muscle> primaryMuscles,
    @Default([]) List<Muscle> secondaryMuscles,
    ForceType? force,
    required LevelType level,
    MechanicType? mechanic,
    EquipmentType? equipment,
    required CategoryType category,
    @Default([]) List<String> instructions,
    String? description,
    @Default([]) List<String> tips,
    String? image,
    DateTime? dateCreated,
    DateTime? dateUpdated,
    @Default(false) bool isFavorite,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
}
