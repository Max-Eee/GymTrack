// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_log_exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkoutLogExercise _$WorkoutLogExerciseFromJson(Map<String, dynamic> json) {
  return _WorkoutLogExercise.fromJson(json);
}

/// @nodoc
mixin _$WorkoutLogExercise {
  String get id => throw _privateConstructorUsedError;
  String get workoutLogId => throw _privateConstructorUsedError;
  String get exerciseId => throw _privateConstructorUsedError;
  TrackingType get trackingType => throw _privateConstructorUsedError;

  /// Serializes this WorkoutLogExercise to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkoutLogExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkoutLogExerciseCopyWith<WorkoutLogExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutLogExerciseCopyWith<$Res> {
  factory $WorkoutLogExerciseCopyWith(
          WorkoutLogExercise value, $Res Function(WorkoutLogExercise) then) =
      _$WorkoutLogExerciseCopyWithImpl<$Res, WorkoutLogExercise>;
  @useResult
  $Res call(
      {String id,
      String workoutLogId,
      String exerciseId,
      TrackingType trackingType});
}

/// @nodoc
class _$WorkoutLogExerciseCopyWithImpl<$Res, $Val extends WorkoutLogExercise>
    implements $WorkoutLogExerciseCopyWith<$Res> {
  _$WorkoutLogExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkoutLogExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workoutLogId = null,
    Object? exerciseId = null,
    Object? trackingType = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workoutLogId: null == workoutLogId
          ? _value.workoutLogId
          : workoutLogId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      trackingType: null == trackingType
          ? _value.trackingType
          : trackingType // ignore: cast_nullable_to_non_nullable
              as TrackingType,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutLogExerciseImplCopyWith<$Res>
    implements $WorkoutLogExerciseCopyWith<$Res> {
  factory _$$WorkoutLogExerciseImplCopyWith(_$WorkoutLogExerciseImpl value,
          $Res Function(_$WorkoutLogExerciseImpl) then) =
      __$$WorkoutLogExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String workoutLogId,
      String exerciseId,
      TrackingType trackingType});
}

/// @nodoc
class __$$WorkoutLogExerciseImplCopyWithImpl<$Res>
    extends _$WorkoutLogExerciseCopyWithImpl<$Res, _$WorkoutLogExerciseImpl>
    implements _$$WorkoutLogExerciseImplCopyWith<$Res> {
  __$$WorkoutLogExerciseImplCopyWithImpl(_$WorkoutLogExerciseImpl _value,
      $Res Function(_$WorkoutLogExerciseImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkoutLogExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workoutLogId = null,
    Object? exerciseId = null,
    Object? trackingType = null,
  }) {
    return _then(_$WorkoutLogExerciseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workoutLogId: null == workoutLogId
          ? _value.workoutLogId
          : workoutLogId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      trackingType: null == trackingType
          ? _value.trackingType
          : trackingType // ignore: cast_nullable_to_non_nullable
              as TrackingType,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutLogExerciseImpl implements _WorkoutLogExercise {
  const _$WorkoutLogExerciseImpl(
      {required this.id,
      required this.workoutLogId,
      required this.exerciseId,
      required this.trackingType});

  factory _$WorkoutLogExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutLogExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String workoutLogId;
  @override
  final String exerciseId;
  @override
  final TrackingType trackingType;

  @override
  String toString() {
    return 'WorkoutLogExercise(id: $id, workoutLogId: $workoutLogId, exerciseId: $exerciseId, trackingType: $trackingType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutLogExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workoutLogId, workoutLogId) ||
                other.workoutLogId == workoutLogId) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.trackingType, trackingType) ||
                other.trackingType == trackingType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, workoutLogId, exerciseId, trackingType);

  /// Create a copy of WorkoutLogExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutLogExerciseImplCopyWith<_$WorkoutLogExerciseImpl> get copyWith =>
      __$$WorkoutLogExerciseImplCopyWithImpl<_$WorkoutLogExerciseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutLogExerciseImplToJson(
      this,
    );
  }
}

abstract class _WorkoutLogExercise implements WorkoutLogExercise {
  const factory _WorkoutLogExercise(
      {required final String id,
      required final String workoutLogId,
      required final String exerciseId,
      required final TrackingType trackingType}) = _$WorkoutLogExerciseImpl;

  factory _WorkoutLogExercise.fromJson(Map<String, dynamic> json) =
      _$WorkoutLogExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get workoutLogId;
  @override
  String get exerciseId;
  @override
  TrackingType get trackingType;

  /// Create a copy of WorkoutLogExercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkoutLogExerciseImplCopyWith<_$WorkoutLogExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
