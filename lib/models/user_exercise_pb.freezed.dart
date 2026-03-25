// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_exercise_pb.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserExercisePB _$UserExercisePBFromJson(Map<String, dynamic> json) {
  return _UserExercisePB.fromJson(json);
}

/// @nodoc
mixin _$UserExercisePB {
  String get exerciseId => throw _privateConstructorUsedError;
  double get weight => throw _privateConstructorUsedError;
  int? get reps => throw _privateConstructorUsedError;
  int? get exerciseDuration => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String? get workoutLogId => throw _privateConstructorUsedError;

  /// Serializes this UserExercisePB to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserExercisePB
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserExercisePBCopyWith<UserExercisePB> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserExercisePBCopyWith<$Res> {
  factory $UserExercisePBCopyWith(
          UserExercisePB value, $Res Function(UserExercisePB) then) =
      _$UserExercisePBCopyWithImpl<$Res, UserExercisePB>;
  @useResult
  $Res call(
      {String exerciseId,
      double weight,
      int? reps,
      int? exerciseDuration,
      DateTime? createdAt,
      String? workoutLogId});
}

/// @nodoc
class _$UserExercisePBCopyWithImpl<$Res, $Val extends UserExercisePB>
    implements $UserExercisePBCopyWith<$Res> {
  _$UserExercisePBCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserExercisePB
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? weight = null,
    Object? reps = freezed,
    Object? exerciseDuration = freezed,
    Object? createdAt = freezed,
    Object? workoutLogId = freezed,
  }) {
    return _then(_value.copyWith(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: freezed == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      exerciseDuration: freezed == exerciseDuration
          ? _value.exerciseDuration
          : exerciseDuration // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      workoutLogId: freezed == workoutLogId
          ? _value.workoutLogId
          : workoutLogId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserExercisePBImplCopyWith<$Res>
    implements $UserExercisePBCopyWith<$Res> {
  factory _$$UserExercisePBImplCopyWith(_$UserExercisePBImpl value,
          $Res Function(_$UserExercisePBImpl) then) =
      __$$UserExercisePBImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String exerciseId,
      double weight,
      int? reps,
      int? exerciseDuration,
      DateTime? createdAt,
      String? workoutLogId});
}

/// @nodoc
class __$$UserExercisePBImplCopyWithImpl<$Res>
    extends _$UserExercisePBCopyWithImpl<$Res, _$UserExercisePBImpl>
    implements _$$UserExercisePBImplCopyWith<$Res> {
  __$$UserExercisePBImplCopyWithImpl(
      _$UserExercisePBImpl _value, $Res Function(_$UserExercisePBImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserExercisePB
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? weight = null,
    Object? reps = freezed,
    Object? exerciseDuration = freezed,
    Object? createdAt = freezed,
    Object? workoutLogId = freezed,
  }) {
    return _then(_$UserExercisePBImpl(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: freezed == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      exerciseDuration: freezed == exerciseDuration
          ? _value.exerciseDuration
          : exerciseDuration // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      workoutLogId: freezed == workoutLogId
          ? _value.workoutLogId
          : workoutLogId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserExercisePBImpl implements _UserExercisePB {
  const _$UserExercisePBImpl(
      {required this.exerciseId,
      required this.weight,
      this.reps,
      this.exerciseDuration,
      this.createdAt,
      this.workoutLogId});

  factory _$UserExercisePBImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserExercisePBImplFromJson(json);

  @override
  final String exerciseId;
  @override
  final double weight;
  @override
  final int? reps;
  @override
  final int? exerciseDuration;
  @override
  final DateTime? createdAt;
  @override
  final String? workoutLogId;

  @override
  String toString() {
    return 'UserExercisePB(exerciseId: $exerciseId, weight: $weight, reps: $reps, exerciseDuration: $exerciseDuration, createdAt: $createdAt, workoutLogId: $workoutLogId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserExercisePBImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.exerciseDuration, exerciseDuration) ||
                other.exerciseDuration == exerciseDuration) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.workoutLogId, workoutLogId) ||
                other.workoutLogId == workoutLogId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, exerciseId, weight, reps,
      exerciseDuration, createdAt, workoutLogId);

  /// Create a copy of UserExercisePB
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserExercisePBImplCopyWith<_$UserExercisePBImpl> get copyWith =>
      __$$UserExercisePBImplCopyWithImpl<_$UserExercisePBImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserExercisePBImplToJson(
      this,
    );
  }
}

abstract class _UserExercisePB implements UserExercisePB {
  const factory _UserExercisePB(
      {required final String exerciseId,
      required final double weight,
      final int? reps,
      final int? exerciseDuration,
      final DateTime? createdAt,
      final String? workoutLogId}) = _$UserExercisePBImpl;

  factory _UserExercisePB.fromJson(Map<String, dynamic> json) =
      _$UserExercisePBImpl.fromJson;

  @override
  String get exerciseId;
  @override
  double get weight;
  @override
  int? get reps;
  @override
  int? get exerciseDuration;
  @override
  DateTime? get createdAt;
  @override
  String? get workoutLogId;

  /// Create a copy of UserExercisePB
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserExercisePBImplCopyWith<_$UserExercisePBImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
