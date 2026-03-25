import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'workout_log_exercise.freezed.dart';
part 'workout_log_exercise.g.dart';

@freezed
class WorkoutLogExercise with _$WorkoutLogExercise {
  const factory WorkoutLogExercise({
    required String id,
    required String workoutLogId,
    required String exerciseId,
    required TrackingType trackingType,
  }) = _WorkoutLogExercise;

  factory WorkoutLogExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutLogExerciseFromJson(json);
}
