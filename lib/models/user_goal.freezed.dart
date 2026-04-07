// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_goal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserGoal _$UserGoalFromJson(Map<String, dynamic> json) {
  return _UserGoal.fromJson(json);
}

/// @nodoc
mixin _$UserGoal {
  String get id => throw _privateConstructorUsedError;
  String get exerciseId => throw _privateConstructorUsedError;
  GoalType get goalType => throw _privateConstructorUsedError;
  double get goalValue => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserGoalCopyWith<UserGoal> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserGoalCopyWith<$Res> {
  factory $UserGoalCopyWith(UserGoal value, $Res Function(UserGoal) then) =
      _$UserGoalCopyWithImpl<$Res, UserGoal>;
  @useResult
  $Res call(
      {String id,
      String exerciseId,
      GoalType goalType,
      double goalValue,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$UserGoalCopyWithImpl<$Res, $Val extends UserGoal>
    implements $UserGoalCopyWith<$Res> {
  _$UserGoalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseId = null,
    Object? goalType = null,
    Object? goalValue = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      goalType: null == goalType
          ? _value.goalType
          : goalType // ignore: cast_nullable_to_non_nullable
              as GoalType,
      goalValue: null == goalValue
          ? _value.goalValue
          : goalValue // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserGoalImplCopyWith<$Res>
    implements $UserGoalCopyWith<$Res> {
  factory _$$UserGoalImplCopyWith(
          _$UserGoalImpl value, $Res Function(_$UserGoalImpl) then) =
      __$$UserGoalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String exerciseId,
      GoalType goalType,
      double goalValue,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$UserGoalImplCopyWithImpl<$Res>
    extends _$UserGoalCopyWithImpl<$Res, _$UserGoalImpl>
    implements _$$UserGoalImplCopyWith<$Res> {
  __$$UserGoalImplCopyWithImpl(
      _$UserGoalImpl _value, $Res Function(_$UserGoalImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseId = null,
    Object? goalType = null,
    Object? goalValue = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$UserGoalImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      goalType: null == goalType
          ? _value.goalType
          : goalType // ignore: cast_nullable_to_non_nullable
              as GoalType,
      goalValue: null == goalValue
          ? _value.goalValue
          : goalValue // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserGoalImpl implements _UserGoal {
  const _$UserGoalImpl(
      {required this.id,
      required this.exerciseId,
      required this.goalType,
      required this.goalValue,
      this.createdAt,
      this.updatedAt});

  factory _$UserGoalImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserGoalImplFromJson(json);

  @override
  final String id;
  @override
  final String exerciseId;
  @override
  final GoalType goalType;
  @override
  final double goalValue;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserGoal(id: $id, exerciseId: $exerciseId, goalType: $goalType, goalValue: $goalValue, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserGoalImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.goalType, goalType) ||
                other.goalType == goalType) &&
            (identical(other.goalValue, goalValue) ||
                other.goalValue == goalValue) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, exerciseId, goalType, goalValue, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserGoalImplCopyWith<_$UserGoalImpl> get copyWith =>
      __$$UserGoalImplCopyWithImpl<_$UserGoalImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserGoalImplToJson(
      this,
    );
  }
}

abstract class _UserGoal implements UserGoal {
  const factory _UserGoal(
      {required final String id,
      required final String exerciseId,
      required final GoalType goalType,
      required final double goalValue,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$UserGoalImpl;

  factory _UserGoal.fromJson(Map<String, dynamic> json) =
      _$UserGoalImpl.fromJson;

  @override
  String get id;
  @override
  String get exerciseId;
  @override
  GoalType get goalType;
  @override
  double get goalValue;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserGoalImplCopyWith<_$UserGoalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
