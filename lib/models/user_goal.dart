import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'user_goal.freezed.dart';
part 'user_goal.g.dart';

@freezed
class UserGoal with _$UserGoal {
  const factory UserGoal({
    required String id,
    required String exerciseId,
    required GoalType goalType,
    required double goalValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserGoal;

  factory UserGoal.fromJson(Map<String, dynamic> json) =>
      _$UserGoalFromJson(json);
}
