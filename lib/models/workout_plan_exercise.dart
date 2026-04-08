import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'workout_plan_exercise.freezed.dart';
part 'workout_plan_exercise.g.dart';

@freezed
class WorkoutPlanExercise with _$WorkoutPlanExercise {
  const factory WorkoutPlanExercise({
    required String id,
    required String workoutPlanId,
    required String exerciseId,
    required int sets,
    int? reps,
    int? exerciseDuration,
    int? order,
    required TrackingType trackingType,
  }) = _WorkoutPlanExercise;

  factory WorkoutPlanExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutPlanExerciseFromJson(json);
}
