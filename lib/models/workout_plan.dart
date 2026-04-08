import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_plan.freezed.dart';
part 'workout_plan.g.dart';

@freezed
class WorkoutPlan with _$WorkoutPlan {
  const factory WorkoutPlan({
    required String id,
    required String name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    @Default(false) bool isSystemRoutine,
    String? systemRoutineCategory,
  }) = _WorkoutPlan;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) =>
      _$WorkoutPlanFromJson(json);
}
