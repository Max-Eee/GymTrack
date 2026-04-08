import 'package:freezed_annotation/freezed_annotation.dart';

part 'set_log.freezed.dart';
part 'set_log.g.dart';

@freezed
class SetLog with _$SetLog {
  const factory SetLog({
    required String id,
    required String workoutLogExerciseId,
    double? weight,
    int? reps,
    int? exerciseDuration,
    int? order,
    @Default(false) bool isWarmUp,
  }) = _SetLog;

  factory SetLog.fromJson(Map<String, dynamic> json) =>
      _$SetLogFromJson(json);
}
