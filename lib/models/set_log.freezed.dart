// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'set_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SetLog _$SetLogFromJson(Map<String, dynamic> json) {
  return _SetLog.fromJson(json);
}

/// @nodoc
mixin _$SetLog {
  String get id => throw _privateConstructorUsedError;
  String get workoutLogExerciseId => throw _privateConstructorUsedError;
  double? get weight => throw _privateConstructorUsedError;
  int? get reps => throw _privateConstructorUsedError;
  int? get exerciseDuration => throw _privateConstructorUsedError;
  int? get order => throw _privateConstructorUsedError;
  bool get isWarmUp => throw _privateConstructorUsedError;

  /// Serializes this SetLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SetLogCopyWith<SetLog> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetLogCopyWith<$Res> {
  factory $SetLogCopyWith(SetLog value, $Res Function(SetLog) then) =
      _$SetLogCopyWithImpl<$Res, SetLog>;
  @useResult
  $Res call(
      {String id,
      String workoutLogExerciseId,
      double? weight,
      int? reps,
      int? exerciseDuration,
      int? order,
      bool isWarmUp});
}

/// @nodoc
class _$SetLogCopyWithImpl<$Res, $Val extends SetLog>
    implements $SetLogCopyWith<$Res> {
  _$SetLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workoutLogExerciseId = null,
    Object? weight = freezed,
    Object? reps = freezed,
    Object? exerciseDuration = freezed,
    Object? order = freezed,
    Object? isWarmUp = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workoutLogExerciseId: null == workoutLogExerciseId
          ? _value.workoutLogExerciseId
          : workoutLogExerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      weight: freezed == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double?,
      reps: freezed == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      exerciseDuration: freezed == exerciseDuration
          ? _value.exerciseDuration
          : exerciseDuration // ignore: cast_nullable_to_non_nullable
              as int?,
      order: freezed == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int?,
      isWarmUp: null == isWarmUp
          ? _value.isWarmUp
          : isWarmUp // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SetLogImplCopyWith<$Res> implements $SetLogCopyWith<$Res> {
  factory _$$SetLogImplCopyWith(
          _$SetLogImpl value, $Res Function(_$SetLogImpl) then) =
      __$$SetLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String workoutLogExerciseId,
      double? weight,
      int? reps,
      int? exerciseDuration,
      int? order,
      bool isWarmUp});
}

/// @nodoc
class __$$SetLogImplCopyWithImpl<$Res>
    extends _$SetLogCopyWithImpl<$Res, _$SetLogImpl>
    implements _$$SetLogImplCopyWith<$Res> {
  __$$SetLogImplCopyWithImpl(
      _$SetLogImpl _value, $Res Function(_$SetLogImpl) _then)
      : super(_value, _then);

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workoutLogExerciseId = null,
    Object? weight = freezed,
    Object? reps = freezed,
    Object? exerciseDuration = freezed,
    Object? order = freezed,
    Object? isWarmUp = null,
  }) {
    return _then(_$SetLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workoutLogExerciseId: null == workoutLogExerciseId
          ? _value.workoutLogExerciseId
          : workoutLogExerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      weight: freezed == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double?,
      reps: freezed == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      exerciseDuration: freezed == exerciseDuration
          ? _value.exerciseDuration
          : exerciseDuration // ignore: cast_nullable_to_non_nullable
              as int?,
      order: freezed == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int?,
      isWarmUp: null == isWarmUp
          ? _value.isWarmUp
          : isWarmUp // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SetLogImpl implements _SetLog {
  const _$SetLogImpl(
      {required this.id,
      required this.workoutLogExerciseId,
      this.weight,
      this.reps,
      this.exerciseDuration,
      this.order,
      this.isWarmUp = false});

  factory _$SetLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$SetLogImplFromJson(json);

  @override
  final String id;
  @override
  final String workoutLogExerciseId;
  @override
  final double? weight;
  @override
  final int? reps;
  @override
  final int? exerciseDuration;
  @override
  final int? order;
  @override
  @JsonKey()
  final bool isWarmUp;

  @override
  String toString() {
    return 'SetLog(id: $id, workoutLogExerciseId: $workoutLogExerciseId, weight: $weight, reps: $reps, exerciseDuration: $exerciseDuration, order: $order, isWarmUp: $isWarmUp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workoutLogExerciseId, workoutLogExerciseId) ||
                other.workoutLogExerciseId == workoutLogExerciseId) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.exerciseDuration, exerciseDuration) ||
                other.exerciseDuration == exerciseDuration) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.isWarmUp, isWarmUp) ||
                other.isWarmUp == isWarmUp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, workoutLogExerciseId, weight,
      reps, exerciseDuration, order, isWarmUp);

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SetLogImplCopyWith<_$SetLogImpl> get copyWith =>
      __$$SetLogImplCopyWithImpl<_$SetLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SetLogImplToJson(
      this,
    );
  }
}

abstract class _SetLog implements SetLog {
  const factory _SetLog(
      {required final String id,
      required final String workoutLogExerciseId,
      final double? weight,
      final int? reps,
      final int? exerciseDuration,
      final int? order,
      final bool isWarmUp}) = _$SetLogImpl;

  factory _SetLog.fromJson(Map<String, dynamic> json) = _$SetLogImpl.fromJson;

  @override
  String get id;
  @override
  String get workoutLogExerciseId;
  @override
  double? get weight;
  @override
  int? get reps;
  @override
  int? get exerciseDuration;
  @override
  int? get order;
  @override
  bool get isWarmUp;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SetLogImplCopyWith<_$SetLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
