// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkoutLog _$WorkoutLogFromJson(Map<String, dynamic> json) {
  return _WorkoutLog.fromJson(json);
}

/// @nodoc
mixin _$WorkoutLog {
  String get id => throw _privateConstructorUsedError;
  String get workoutPlanId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  bool get inProgress => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get dateUpdated => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutLogCopyWith<WorkoutLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutLogCopyWith<$Res> {
  factory $WorkoutLogCopyWith(
          WorkoutLog value, $Res Function(WorkoutLog) then) =
      _$WorkoutLogCopyWithImpl<$Res, WorkoutLog>;
  @useResult
  $Res call(
      {String id,
      String workoutPlanId,
      DateTime date,
      int duration,
      bool inProgress,
      DateTime? createdAt,
      DateTime? dateUpdated});
}

/// @nodoc
class _$WorkoutLogCopyWithImpl<$Res, $Val extends WorkoutLog>
    implements $WorkoutLogCopyWith<$Res> {
  _$WorkoutLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workoutPlanId = null,
    Object? date = null,
    Object? duration = null,
    Object? inProgress = null,
    Object? createdAt = freezed,
    Object? dateUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workoutPlanId: null == workoutPlanId
          ? _value.workoutPlanId
          : workoutPlanId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      inProgress: null == inProgress
          ? _value.inProgress
          : inProgress // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateUpdated: freezed == dateUpdated
          ? _value.dateUpdated
          : dateUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutLogImplCopyWith<$Res>
    implements $WorkoutLogCopyWith<$Res> {
  factory _$$WorkoutLogImplCopyWith(
          _$WorkoutLogImpl value, $Res Function(_$WorkoutLogImpl) then) =
      __$$WorkoutLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String workoutPlanId,
      DateTime date,
      int duration,
      bool inProgress,
      DateTime? createdAt,
      DateTime? dateUpdated});
}

/// @nodoc
class __$$WorkoutLogImplCopyWithImpl<$Res>
    extends _$WorkoutLogCopyWithImpl<$Res, _$WorkoutLogImpl>
    implements _$$WorkoutLogImplCopyWith<$Res> {
  __$$WorkoutLogImplCopyWithImpl(
      _$WorkoutLogImpl _value, $Res Function(_$WorkoutLogImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workoutPlanId = null,
    Object? date = null,
    Object? duration = null,
    Object? inProgress = null,
    Object? createdAt = freezed,
    Object? dateUpdated = freezed,
  }) {
    return _then(_$WorkoutLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workoutPlanId: null == workoutPlanId
          ? _value.workoutPlanId
          : workoutPlanId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      inProgress: null == inProgress
          ? _value.inProgress
          : inProgress // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateUpdated: freezed == dateUpdated
          ? _value.dateUpdated
          : dateUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutLogImpl implements _WorkoutLog {
  const _$WorkoutLogImpl(
      {required this.id,
      required this.workoutPlanId,
      required this.date,
      required this.duration,
      this.inProgress = true,
      this.createdAt,
      this.dateUpdated});

  factory _$WorkoutLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutLogImplFromJson(json);

  @override
  final String id;
  @override
  final String workoutPlanId;
  @override
  final DateTime date;
  @override
  final int duration;
  @override
  @JsonKey()
  final bool inProgress;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? dateUpdated;

  @override
  String toString() {
    return 'WorkoutLog(id: $id, workoutPlanId: $workoutPlanId, date: $date, duration: $duration, inProgress: $inProgress, createdAt: $createdAt, dateUpdated: $dateUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workoutPlanId, workoutPlanId) ||
                other.workoutPlanId == workoutPlanId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.inProgress, inProgress) ||
                other.inProgress == inProgress) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.dateUpdated, dateUpdated) ||
                other.dateUpdated == dateUpdated));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, workoutPlanId, date,
      duration, inProgress, createdAt, dateUpdated);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutLogImplCopyWith<_$WorkoutLogImpl> get copyWith =>
      __$$WorkoutLogImplCopyWithImpl<_$WorkoutLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutLogImplToJson(
      this,
    );
  }
}

abstract class _WorkoutLog implements WorkoutLog {
  const factory _WorkoutLog(
      {required final String id,
      required final String workoutPlanId,
      required final DateTime date,
      required final int duration,
      final bool inProgress,
      final DateTime? createdAt,
      final DateTime? dateUpdated}) = _$WorkoutLogImpl;

  factory _WorkoutLog.fromJson(Map<String, dynamic> json) =
      _$WorkoutLogImpl.fromJson;

  @override
  String get id;
  @override
  String get workoutPlanId;
  @override
  DateTime get date;
  @override
  int get duration;
  @override
  bool get inProgress;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get dateUpdated;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutLogImplCopyWith<_$WorkoutLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
