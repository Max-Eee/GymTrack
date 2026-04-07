// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Exercise _$ExerciseFromJson(Map<String, dynamic> json) {
  return _Exercise.fromJson(json);
}

/// @nodoc
mixin _$Exercise {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String> get aliases => throw _privateConstructorUsedError;
  List<Muscle> get primaryMuscles => throw _privateConstructorUsedError;
  List<Muscle> get secondaryMuscles => throw _privateConstructorUsedError;
  ForceType? get force => throw _privateConstructorUsedError;
  LevelType get level => throw _privateConstructorUsedError;
  MechanicType? get mechanic => throw _privateConstructorUsedError;
  EquipmentType? get equipment => throw _privateConstructorUsedError;
  CategoryType get category => throw _privateConstructorUsedError;
  List<String> get instructions => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String> get tips => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;
  DateTime? get dateCreated => throw _privateConstructorUsedError;
  DateTime? get dateUpdated => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseCopyWith<Exercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseCopyWith<$Res> {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) then) =
      _$ExerciseCopyWithImpl<$Res, Exercise>;
  @useResult
  $Res call(
      {String id,
      String name,
      List<String> aliases,
      List<Muscle> primaryMuscles,
      List<Muscle> secondaryMuscles,
      ForceType? force,
      LevelType level,
      MechanicType? mechanic,
      EquipmentType? equipment,
      CategoryType category,
      List<String> instructions,
      String? description,
      List<String> tips,
      String? image,
      DateTime? dateCreated,
      DateTime? dateUpdated,
      bool isFavorite});
}

/// @nodoc
class _$ExerciseCopyWithImpl<$Res, $Val extends Exercise>
    implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? aliases = null,
    Object? primaryMuscles = null,
    Object? secondaryMuscles = null,
    Object? force = freezed,
    Object? level = null,
    Object? mechanic = freezed,
    Object? equipment = freezed,
    Object? category = null,
    Object? instructions = null,
    Object? description = freezed,
    Object? tips = null,
    Object? image = freezed,
    Object? dateCreated = freezed,
    Object? dateUpdated = freezed,
    Object? isFavorite = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      aliases: null == aliases
          ? _value.aliases
          : aliases // ignore: cast_nullable_to_non_nullable
              as List<String>,
      primaryMuscles: null == primaryMuscles
          ? _value.primaryMuscles
          : primaryMuscles // ignore: cast_nullable_to_non_nullable
              as List<Muscle>,
      secondaryMuscles: null == secondaryMuscles
          ? _value.secondaryMuscles
          : secondaryMuscles // ignore: cast_nullable_to_non_nullable
              as List<Muscle>,
      force: freezed == force
          ? _value.force
          : force // ignore: cast_nullable_to_non_nullable
              as ForceType?,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as LevelType,
      mechanic: freezed == mechanic
          ? _value.mechanic
          : mechanic // ignore: cast_nullable_to_non_nullable
              as MechanicType?,
      equipment: freezed == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as EquipmentType?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as CategoryType,
      instructions: null == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      tips: null == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<String>,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      dateCreated: freezed == dateCreated
          ? _value.dateCreated
          : dateCreated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateUpdated: freezed == dateUpdated
          ? _value.dateUpdated
          : dateUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseImplCopyWith<$Res>
    implements $ExerciseCopyWith<$Res> {
  factory _$$ExerciseImplCopyWith(
          _$ExerciseImpl value, $Res Function(_$ExerciseImpl) then) =
      __$$ExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      List<String> aliases,
      List<Muscle> primaryMuscles,
      List<Muscle> secondaryMuscles,
      ForceType? force,
      LevelType level,
      MechanicType? mechanic,
      EquipmentType? equipment,
      CategoryType category,
      List<String> instructions,
      String? description,
      List<String> tips,
      String? image,
      DateTime? dateCreated,
      DateTime? dateUpdated,
      bool isFavorite});
}

/// @nodoc
class __$$ExerciseImplCopyWithImpl<$Res>
    extends _$ExerciseCopyWithImpl<$Res, _$ExerciseImpl>
    implements _$$ExerciseImplCopyWith<$Res> {
  __$$ExerciseImplCopyWithImpl(
      _$ExerciseImpl _value, $Res Function(_$ExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? aliases = null,
    Object? primaryMuscles = null,
    Object? secondaryMuscles = null,
    Object? force = freezed,
    Object? level = null,
    Object? mechanic = freezed,
    Object? equipment = freezed,
    Object? category = null,
    Object? instructions = null,
    Object? description = freezed,
    Object? tips = null,
    Object? image = freezed,
    Object? dateCreated = freezed,
    Object? dateUpdated = freezed,
    Object? isFavorite = null,
  }) {
    return _then(_$ExerciseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      aliases: null == aliases
          ? _value._aliases
          : aliases // ignore: cast_nullable_to_non_nullable
              as List<String>,
      primaryMuscles: null == primaryMuscles
          ? _value._primaryMuscles
          : primaryMuscles // ignore: cast_nullable_to_non_nullable
              as List<Muscle>,
      secondaryMuscles: null == secondaryMuscles
          ? _value._secondaryMuscles
          : secondaryMuscles // ignore: cast_nullable_to_non_nullable
              as List<Muscle>,
      force: freezed == force
          ? _value.force
          : force // ignore: cast_nullable_to_non_nullable
              as ForceType?,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as LevelType,
      mechanic: freezed == mechanic
          ? _value.mechanic
          : mechanic // ignore: cast_nullable_to_non_nullable
              as MechanicType?,
      equipment: freezed == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as EquipmentType?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as CategoryType,
      instructions: null == instructions
          ? _value._instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      tips: null == tips
          ? _value._tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<String>,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      dateCreated: freezed == dateCreated
          ? _value.dateCreated
          : dateCreated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateUpdated: freezed == dateUpdated
          ? _value.dateUpdated
          : dateUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseImpl implements _Exercise {
  const _$ExerciseImpl(
      {required this.id,
      required this.name,
      final List<String> aliases = const [],
      final List<Muscle> primaryMuscles = const [],
      final List<Muscle> secondaryMuscles = const [],
      this.force,
      required this.level,
      this.mechanic,
      this.equipment,
      required this.category,
      final List<String> instructions = const [],
      this.description,
      final List<String> tips = const [],
      this.image,
      this.dateCreated,
      this.dateUpdated,
      this.isFavorite = false})
      : _aliases = aliases,
        _primaryMuscles = primaryMuscles,
        _secondaryMuscles = secondaryMuscles,
        _instructions = instructions,
        _tips = tips;

  factory _$ExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<String> _aliases;
  @override
  @JsonKey()
  List<String> get aliases {
    if (_aliases is EqualUnmodifiableListView) return _aliases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_aliases);
  }

  final List<Muscle> _primaryMuscles;
  @override
  @JsonKey()
  List<Muscle> get primaryMuscles {
    if (_primaryMuscles is EqualUnmodifiableListView) return _primaryMuscles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_primaryMuscles);
  }

  final List<Muscle> _secondaryMuscles;
  @override
  @JsonKey()
  List<Muscle> get secondaryMuscles {
    if (_secondaryMuscles is EqualUnmodifiableListView)
      return _secondaryMuscles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_secondaryMuscles);
  }

  @override
  final ForceType? force;
  @override
  final LevelType level;
  @override
  final MechanicType? mechanic;
  @override
  final EquipmentType? equipment;
  @override
  final CategoryType category;
  final List<String> _instructions;
  @override
  @JsonKey()
  List<String> get instructions {
    if (_instructions is EqualUnmodifiableListView) return _instructions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_instructions);
  }

  @override
  final String? description;
  final List<String> _tips;
  @override
  @JsonKey()
  List<String> get tips {
    if (_tips is EqualUnmodifiableListView) return _tips;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tips);
  }

  @override
  final String? image;
  @override
  final DateTime? dateCreated;
  @override
  final DateTime? dateUpdated;
  @override
  @JsonKey()
  final bool isFavorite;

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, aliases: $aliases, primaryMuscles: $primaryMuscles, secondaryMuscles: $secondaryMuscles, force: $force, level: $level, mechanic: $mechanic, equipment: $equipment, category: $category, instructions: $instructions, description: $description, tips: $tips, image: $image, dateCreated: $dateCreated, dateUpdated: $dateUpdated, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._aliases, _aliases) &&
            const DeepCollectionEquality()
                .equals(other._primaryMuscles, _primaryMuscles) &&
            const DeepCollectionEquality()
                .equals(other._secondaryMuscles, _secondaryMuscles) &&
            (identical(other.force, force) || other.force == force) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.mechanic, mechanic) ||
                other.mechanic == mechanic) &&
            (identical(other.equipment, equipment) ||
                other.equipment == equipment) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality()
                .equals(other._instructions, _instructions) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._tips, _tips) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.dateCreated, dateCreated) ||
                other.dateCreated == dateCreated) &&
            (identical(other.dateUpdated, dateUpdated) ||
                other.dateUpdated == dateUpdated) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      const DeepCollectionEquality().hash(_aliases),
      const DeepCollectionEquality().hash(_primaryMuscles),
      const DeepCollectionEquality().hash(_secondaryMuscles),
      force,
      level,
      mechanic,
      equipment,
      category,
      const DeepCollectionEquality().hash(_instructions),
      description,
      const DeepCollectionEquality().hash(_tips),
      image,
      dateCreated,
      dateUpdated,
      isFavorite);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      __$$ExerciseImplCopyWithImpl<_$ExerciseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseImplToJson(
      this,
    );
  }
}

abstract class _Exercise implements Exercise {
  const factory _Exercise(
      {required final String id,
      required final String name,
      final List<String> aliases,
      final List<Muscle> primaryMuscles,
      final List<Muscle> secondaryMuscles,
      final ForceType? force,
      required final LevelType level,
      final MechanicType? mechanic,
      final EquipmentType? equipment,
      required final CategoryType category,
      final List<String> instructions,
      final String? description,
      final List<String> tips,
      final String? image,
      final DateTime? dateCreated,
      final DateTime? dateUpdated,
      final bool isFavorite}) = _$ExerciseImpl;

  factory _Exercise.fromJson(Map<String, dynamic> json) =
      _$ExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<String> get aliases;
  @override
  List<Muscle> get primaryMuscles;
  @override
  List<Muscle> get secondaryMuscles;
  @override
  ForceType? get force;
  @override
  LevelType get level;
  @override
  MechanicType? get mechanic;
  @override
  EquipmentType? get equipment;
  @override
  CategoryType get category;
  @override
  List<String> get instructions;
  @override
  String? get description;
  @override
  List<String> get tips;
  @override
  String? get image;
  @override
  DateTime? get dateCreated;
  @override
  DateTime? get dateUpdated;
  @override
  bool get isFavorite;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
