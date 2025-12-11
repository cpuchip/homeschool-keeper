// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LogEntry _$LogEntryFromJson(Map<String, dynamic> json) {
  return _LogEntry.fromJson(json);
}

/// @nodoc
mixin _$LogEntry {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String? get organizationId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String? get groupId =>
      throw _privateConstructorUsedError; // Links multiple log entries created together (multi-student)
  DateTime get date => throw _privateConstructorUsedError;
  double get hours => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get locationType => throw _privateConstructorUsedError;
  String? get locationId => throw _privateConstructorUsedError;
  String? get locationName => throw _privateConstructorUsedError;
  String get submittedBy => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get schoolYear => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LogEntryCopyWith<LogEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogEntryCopyWith<$Res> {
  factory $LogEntryCopyWith(LogEntry value, $Res Function(LogEntry) then) =
      _$LogEntryCopyWithImpl<$Res, LogEntry>;
  @useResult
  $Res call(
      {String id,
      String familyId,
      String? organizationId,
      String studentId,
      String subjectId,
      String? groupId,
      DateTime date,
      double hours,
      String description,
      String locationType,
      String? locationId,
      String? locationName,
      String submittedBy,
      String status,
      String schoolYear,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$LogEntryCopyWithImpl<$Res, $Val extends LogEntry>
    implements $LogEntryCopyWith<$Res> {
  _$LogEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? organizationId = freezed,
    Object? studentId = null,
    Object? subjectId = null,
    Object? groupId = freezed,
    Object? date = null,
    Object? hours = null,
    Object? description = null,
    Object? locationType = null,
    Object? locationId = freezed,
    Object? locationName = freezed,
    Object? submittedBy = null,
    Object? status = null,
    Object? schoolYear = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      organizationId: freezed == organizationId
          ? _value.organizationId
          : organizationId // ignore: cast_nullable_to_non_nullable
              as String?,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hours: null == hours
          ? _value.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as double,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      locationType: null == locationType
          ? _value.locationType
          : locationType // ignore: cast_nullable_to_non_nullable
              as String,
      locationId: freezed == locationId
          ? _value.locationId
          : locationId // ignore: cast_nullable_to_non_nullable
              as String?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      submittedBy: null == submittedBy
          ? _value.submittedBy
          : submittedBy // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      schoolYear: null == schoolYear
          ? _value.schoolYear
          : schoolYear // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LogEntryImplCopyWith<$Res>
    implements $LogEntryCopyWith<$Res> {
  factory _$$LogEntryImplCopyWith(
          _$LogEntryImpl value, $Res Function(_$LogEntryImpl) then) =
      __$$LogEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String familyId,
      String? organizationId,
      String studentId,
      String subjectId,
      String? groupId,
      DateTime date,
      double hours,
      String description,
      String locationType,
      String? locationId,
      String? locationName,
      String submittedBy,
      String status,
      String schoolYear,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$LogEntryImplCopyWithImpl<$Res>
    extends _$LogEntryCopyWithImpl<$Res, _$LogEntryImpl>
    implements _$$LogEntryImplCopyWith<$Res> {
  __$$LogEntryImplCopyWithImpl(
      _$LogEntryImpl _value, $Res Function(_$LogEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? organizationId = freezed,
    Object? studentId = null,
    Object? subjectId = null,
    Object? groupId = freezed,
    Object? date = null,
    Object? hours = null,
    Object? description = null,
    Object? locationType = null,
    Object? locationId = freezed,
    Object? locationName = freezed,
    Object? submittedBy = null,
    Object? status = null,
    Object? schoolYear = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$LogEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      organizationId: freezed == organizationId
          ? _value.organizationId
          : organizationId // ignore: cast_nullable_to_non_nullable
              as String?,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hours: null == hours
          ? _value.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as double,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      locationType: null == locationType
          ? _value.locationType
          : locationType // ignore: cast_nullable_to_non_nullable
              as String,
      locationId: freezed == locationId
          ? _value.locationId
          : locationId // ignore: cast_nullable_to_non_nullable
              as String?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      submittedBy: null == submittedBy
          ? _value.submittedBy
          : submittedBy // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      schoolYear: null == schoolYear
          ? _value.schoolYear
          : schoolYear // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LogEntryImpl implements _LogEntry {
  const _$LogEntryImpl(
      {required this.id,
      required this.familyId,
      this.organizationId,
      required this.studentId,
      required this.subjectId,
      this.groupId,
      required this.date,
      required this.hours,
      required this.description,
      required this.locationType,
      this.locationId,
      this.locationName,
      required this.submittedBy,
      required this.status,
      required this.schoolYear,
      required this.createdAt,
      required this.updatedAt});

  factory _$LogEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String? organizationId;
  @override
  final String studentId;
  @override
  final String subjectId;
  @override
  final String? groupId;
// Links multiple log entries created together (multi-student)
  @override
  final DateTime date;
  @override
  final double hours;
  @override
  final String description;
  @override
  final String locationType;
  @override
  final String? locationId;
  @override
  final String? locationName;
  @override
  final String submittedBy;
  @override
  final String status;
  @override
  final String schoolYear;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'LogEntry(id: $id, familyId: $familyId, organizationId: $organizationId, studentId: $studentId, subjectId: $subjectId, groupId: $groupId, date: $date, hours: $hours, description: $description, locationType: $locationType, locationId: $locationId, locationName: $locationName, submittedBy: $submittedBy, status: $status, schoolYear: $schoolYear, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.organizationId, organizationId) ||
                other.organizationId == organizationId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.locationType, locationType) ||
                other.locationType == locationType) &&
            (identical(other.locationId, locationId) ||
                other.locationId == locationId) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.submittedBy, submittedBy) ||
                other.submittedBy == submittedBy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.schoolYear, schoolYear) ||
                other.schoolYear == schoolYear) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      familyId,
      organizationId,
      studentId,
      subjectId,
      groupId,
      date,
      hours,
      description,
      locationType,
      locationId,
      locationName,
      submittedBy,
      status,
      schoolYear,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LogEntryImplCopyWith<_$LogEntryImpl> get copyWith =>
      __$$LogEntryImplCopyWithImpl<_$LogEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LogEntryImplToJson(
      this,
    );
  }
}

abstract class _LogEntry implements LogEntry {
  const factory _LogEntry(
      {required final String id,
      required final String familyId,
      final String? organizationId,
      required final String studentId,
      required final String subjectId,
      final String? groupId,
      required final DateTime date,
      required final double hours,
      required final String description,
      required final String locationType,
      final String? locationId,
      final String? locationName,
      required final String submittedBy,
      required final String status,
      required final String schoolYear,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$LogEntryImpl;

  factory _LogEntry.fromJson(Map<String, dynamic> json) =
      _$LogEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String? get organizationId;
  @override
  String get studentId;
  @override
  String get subjectId;
  @override
  String? get groupId;
  @override // Links multiple log entries created together (multi-student)
  DateTime get date;
  @override
  double get hours;
  @override
  String get description;
  @override
  String get locationType;
  @override
  String? get locationId;
  @override
  String? get locationName;
  @override
  String get submittedBy;
  @override
  String get status;
  @override
  String get schoolYear;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$LogEntryImplCopyWith<_$LogEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
