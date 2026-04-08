import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_exercise_pb.freezed.dart';
part 'user_exercise_pb.g.dart';

@freezed
class UserExercisePB with _$UserExercisePB {
  const factory UserExercisePB({
    required String exerciseId,
    required double weight,
    int? reps,
    int? exerciseDuration,
    DateTime? createdAt,
    String? workoutLogId,
  }) = _UserExercisePB;

  factory UserExercisePB.fromJson(Map<String, dynamic> json) =>
      _$UserExercisePBFromJson(json);
}
