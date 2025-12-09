// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SubjectHours _$SubjectHoursFromJson(Map<String, dynamic> json) {
  return _SubjectHours.fromJson(json);
}

/// @nodoc
mixin _$SubjectHours {
  String get subjectId => throw _privateConstructorUsedError;
  String get subjectName => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  double get hours => throw _privateConstructorUsedError;
  double? get targetHours => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SubjectHoursCopyWith<SubjectHours> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubjectHoursCopyWith<$Res> {
  factory $SubjectHoursCopyWith(
          SubjectHours value, $Res Function(SubjectHours) then) =
      _$SubjectHoursCopyWithImpl<$Res, SubjectHours>;
  @useResult
  $Res call(
      {String subjectId,
      String subjectName,
      String color,
      double hours,
      double? targetHours,
      double progress});
}

/// @nodoc
class _$SubjectHoursCopyWithImpl<$Res, $Val extends SubjectHours>
    implements $SubjectHoursCopyWith<$Res> {
  _$SubjectHoursCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subjectId = null,
    Object? subjectName = null,
    Object? color = null,
    Object? hours = null,
    Object? targetHours = freezed,
    Object? progress = null,
  }) {
    return _then(_value.copyWith(
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      hours: null == hours
          ? _value.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as double,
      targetHours: freezed == targetHours
          ? _value.targetHours
          : targetHours // ignore: cast_nullable_to_non_nullable
              as double?,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubjectHoursImplCopyWith<$Res>
    implements $SubjectHoursCopyWith<$Res> {
  factory _$$SubjectHoursImplCopyWith(
          _$SubjectHoursImpl value, $Res Function(_$SubjectHoursImpl) then) =
      __$$SubjectHoursImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String subjectId,
      String subjectName,
      String color,
      double hours,
      double? targetHours,
      double progress});
}

/// @nodoc
class __$$SubjectHoursImplCopyWithImpl<$Res>
    extends _$SubjectHoursCopyWithImpl<$Res, _$SubjectHoursImpl>
    implements _$$SubjectHoursImplCopyWith<$Res> {
  __$$SubjectHoursImplCopyWithImpl(
      _$SubjectHoursImpl _value, $Res Function(_$SubjectHoursImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subjectId = null,
    Object? subjectName = null,
    Object? color = null,
    Object? hours = null,
    Object? targetHours = freezed,
    Object? progress = null,
  }) {
    return _then(_$SubjectHoursImpl(
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      hours: null == hours
          ? _value.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as double,
      targetHours: freezed == targetHours
          ? _value.targetHours
          : targetHours // ignore: cast_nullable_to_non_nullable
              as double?,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubjectHoursImpl implements _SubjectHours {
  const _$SubjectHoursImpl(
      {required this.subjectId,
      required this.subjectName,
      required this.color,
      required this.hours,
      this.targetHours,
      required this.progress});

  factory _$SubjectHoursImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubjectHoursImplFromJson(json);

  @override
  final String subjectId;
  @override
  final String subjectName;
  @override
  final String color;
  @override
  final double hours;
  @override
  final double? targetHours;
  @override
  final double progress;

  @override
  String toString() {
    return 'SubjectHours(subjectId: $subjectId, subjectName: $subjectName, color: $color, hours: $hours, targetHours: $targetHours, progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubjectHoursImpl &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.targetHours, targetHours) ||
                other.targetHours == targetHours) &&
            (identical(other.progress, progress) ||
                other.progress == progress));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, subjectId, subjectName, color, hours, targetHours, progress);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SubjectHoursImplCopyWith<_$SubjectHoursImpl> get copyWith =>
      __$$SubjectHoursImplCopyWithImpl<_$SubjectHoursImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubjectHoursImplToJson(
      this,
    );
  }
}

abstract class _SubjectHours implements SubjectHours {
  const factory _SubjectHours(
      {required final String subjectId,
      required final String subjectName,
      required final String color,
      required final double hours,
      final double? targetHours,
      required final double progress}) = _$SubjectHoursImpl;

  factory _SubjectHours.fromJson(Map<String, dynamic> json) =
      _$SubjectHoursImpl.fromJson;

  @override
  String get subjectId;
  @override
  String get subjectName;
  @override
  String get color;
  @override
  double get hours;
  @override
  double? get targetHours;
  @override
  double get progress;
  @override
  @JsonKey(ignore: true)
  _$$SubjectHoursImplCopyWith<_$SubjectHoursImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StudentStats _$StudentStatsFromJson(Map<String, dynamic> json) {
  return _StudentStats.fromJson(json);
}

/// @nodoc
mixin _$StudentStats {
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  double get totalHours => throw _privateConstructorUsedError;
  List<SubjectHours> get hoursBySubject => throw _privateConstructorUsedError;
  int get logCount => throw _privateConstructorUsedError;
  String get schoolYear => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudentStatsCopyWith<StudentStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentStatsCopyWith<$Res> {
  factory $StudentStatsCopyWith(
          StudentStats value, $Res Function(StudentStats) then) =
      _$StudentStatsCopyWithImpl<$Res, StudentStats>;
  @useResult
  $Res call(
      {String studentId,
      String studentName,
      double totalHours,
      List<SubjectHours> hoursBySubject,
      int logCount,
      String schoolYear});
}

/// @nodoc
class _$StudentStatsCopyWithImpl<$Res, $Val extends StudentStats>
    implements $StudentStatsCopyWith<$Res> {
  _$StudentStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentName = null,
    Object? totalHours = null,
    Object? hoursBySubject = null,
    Object? logCount = null,
    Object? schoolYear = null,
  }) {
    return _then(_value.copyWith(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      totalHours: null == totalHours
          ? _value.totalHours
          : totalHours // ignore: cast_nullable_to_non_nullable
              as double,
      hoursBySubject: null == hoursBySubject
          ? _value.hoursBySubject
          : hoursBySubject // ignore: cast_nullable_to_non_nullable
              as List<SubjectHours>,
      logCount: null == logCount
          ? _value.logCount
          : logCount // ignore: cast_nullable_to_non_nullable
              as int,
      schoolYear: null == schoolYear
          ? _value.schoolYear
          : schoolYear // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentStatsImplCopyWith<$Res>
    implements $StudentStatsCopyWith<$Res> {
  factory _$$StudentStatsImplCopyWith(
          _$StudentStatsImpl value, $Res Function(_$StudentStatsImpl) then) =
      __$$StudentStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String studentId,
      String studentName,
      double totalHours,
      List<SubjectHours> hoursBySubject,
      int logCount,
      String schoolYear});
}

/// @nodoc
class __$$StudentStatsImplCopyWithImpl<$Res>
    extends _$StudentStatsCopyWithImpl<$Res, _$StudentStatsImpl>
    implements _$$StudentStatsImplCopyWith<$Res> {
  __$$StudentStatsImplCopyWithImpl(
      _$StudentStatsImpl _value, $Res Function(_$StudentStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentName = null,
    Object? totalHours = null,
    Object? hoursBySubject = null,
    Object? logCount = null,
    Object? schoolYear = null,
  }) {
    return _then(_$StudentStatsImpl(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      totalHours: null == totalHours
          ? _value.totalHours
          : totalHours // ignore: cast_nullable_to_non_nullable
              as double,
      hoursBySubject: null == hoursBySubject
          ? _value._hoursBySubject
          : hoursBySubject // ignore: cast_nullable_to_non_nullable
              as List<SubjectHours>,
      logCount: null == logCount
          ? _value.logCount
          : logCount // ignore: cast_nullable_to_non_nullable
              as int,
      schoolYear: null == schoolYear
          ? _value.schoolYear
          : schoolYear // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentStatsImpl implements _StudentStats {
  const _$StudentStatsImpl(
      {required this.studentId,
      required this.studentName,
      required this.totalHours,
      required final List<SubjectHours> hoursBySubject,
      required this.logCount,
      required this.schoolYear})
      : _hoursBySubject = hoursBySubject;

  factory _$StudentStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentStatsImplFromJson(json);

  @override
  final String studentId;
  @override
  final String studentName;
  @override
  final double totalHours;
  final List<SubjectHours> _hoursBySubject;
  @override
  List<SubjectHours> get hoursBySubject {
    if (_hoursBySubject is EqualUnmodifiableListView) return _hoursBySubject;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hoursBySubject);
  }

  @override
  final int logCount;
  @override
  final String schoolYear;

  @override
  String toString() {
    return 'StudentStats(studentId: $studentId, studentName: $studentName, totalHours: $totalHours, hoursBySubject: $hoursBySubject, logCount: $logCount, schoolYear: $schoolYear)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentStatsImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.totalHours, totalHours) ||
                other.totalHours == totalHours) &&
            const DeepCollectionEquality()
                .equals(other._hoursBySubject, _hoursBySubject) &&
            (identical(other.logCount, logCount) ||
                other.logCount == logCount) &&
            (identical(other.schoolYear, schoolYear) ||
                other.schoolYear == schoolYear));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      studentId,
      studentName,
      totalHours,
      const DeepCollectionEquality().hash(_hoursBySubject),
      logCount,
      schoolYear);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentStatsImplCopyWith<_$StudentStatsImpl> get copyWith =>
      __$$StudentStatsImplCopyWithImpl<_$StudentStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentStatsImplToJson(
      this,
    );
  }
}

abstract class _StudentStats implements StudentStats {
  const factory _StudentStats(
      {required final String studentId,
      required final String studentName,
      required final double totalHours,
      required final List<SubjectHours> hoursBySubject,
      required final int logCount,
      required final String schoolYear}) = _$StudentStatsImpl;

  factory _StudentStats.fromJson(Map<String, dynamic> json) =
      _$StudentStatsImpl.fromJson;

  @override
  String get studentId;
  @override
  String get studentName;
  @override
  double get totalHours;
  @override
  List<SubjectHours> get hoursBySubject;
  @override
  int get logCount;
  @override
  String get schoolYear;
  @override
  @JsonKey(ignore: true)
  _$$StudentStatsImplCopyWith<_$StudentStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FamilyStats _$FamilyStatsFromJson(Map<String, dynamic> json) {
  return _FamilyStats.fromJson(json);
}

/// @nodoc
mixin _$FamilyStats {
  double get totalHours => throw _privateConstructorUsedError;
  List<StudentStats> get students => throw _privateConstructorUsedError;
  String get schoolYear => throw _privateConstructorUsedError;
  int get totalLogCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FamilyStatsCopyWith<FamilyStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyStatsCopyWith<$Res> {
  factory $FamilyStatsCopyWith(
          FamilyStats value, $Res Function(FamilyStats) then) =
      _$FamilyStatsCopyWithImpl<$Res, FamilyStats>;
  @useResult
  $Res call(
      {double totalHours,
      List<StudentStats> students,
      String schoolYear,
      int totalLogCount});
}

/// @nodoc
class _$FamilyStatsCopyWithImpl<$Res, $Val extends FamilyStats>
    implements $FamilyStatsCopyWith<$Res> {
  _$FamilyStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalHours = null,
    Object? students = null,
    Object? schoolYear = null,
    Object? totalLogCount = null,
  }) {
    return _then(_value.copyWith(
      totalHours: null == totalHours
          ? _value.totalHours
          : totalHours // ignore: cast_nullable_to_non_nullable
              as double,
      students: null == students
          ? _value.students
          : students // ignore: cast_nullable_to_non_nullable
              as List<StudentStats>,
      schoolYear: null == schoolYear
          ? _value.schoolYear
          : schoolYear // ignore: cast_nullable_to_non_nullable
              as String,
      totalLogCount: null == totalLogCount
          ? _value.totalLogCount
          : totalLogCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FamilyStatsImplCopyWith<$Res>
    implements $FamilyStatsCopyWith<$Res> {
  factory _$$FamilyStatsImplCopyWith(
          _$FamilyStatsImpl value, $Res Function(_$FamilyStatsImpl) then) =
      __$$FamilyStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double totalHours,
      List<StudentStats> students,
      String schoolYear,
      int totalLogCount});
}

/// @nodoc
class __$$FamilyStatsImplCopyWithImpl<$Res>
    extends _$FamilyStatsCopyWithImpl<$Res, _$FamilyStatsImpl>
    implements _$$FamilyStatsImplCopyWith<$Res> {
  __$$FamilyStatsImplCopyWithImpl(
      _$FamilyStatsImpl _value, $Res Function(_$FamilyStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalHours = null,
    Object? students = null,
    Object? schoolYear = null,
    Object? totalLogCount = null,
  }) {
    return _then(_$FamilyStatsImpl(
      totalHours: null == totalHours
          ? _value.totalHours
          : totalHours // ignore: cast_nullable_to_non_nullable
              as double,
      students: null == students
          ? _value._students
          : students // ignore: cast_nullable_to_non_nullable
              as List<StudentStats>,
      schoolYear: null == schoolYear
          ? _value.schoolYear
          : schoolYear // ignore: cast_nullable_to_non_nullable
              as String,
      totalLogCount: null == totalLogCount
          ? _value.totalLogCount
          : totalLogCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyStatsImpl implements _FamilyStats {
  const _$FamilyStatsImpl(
      {required this.totalHours,
      required final List<StudentStats> students,
      required this.schoolYear,
      required this.totalLogCount})
      : _students = students;

  factory _$FamilyStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyStatsImplFromJson(json);

  @override
  final double totalHours;
  final List<StudentStats> _students;
  @override
  List<StudentStats> get students {
    if (_students is EqualUnmodifiableListView) return _students;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_students);
  }

  @override
  final String schoolYear;
  @override
  final int totalLogCount;

  @override
  String toString() {
    return 'FamilyStats(totalHours: $totalHours, students: $students, schoolYear: $schoolYear, totalLogCount: $totalLogCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyStatsImpl &&
            (identical(other.totalHours, totalHours) ||
                other.totalHours == totalHours) &&
            const DeepCollectionEquality().equals(other._students, _students) &&
            (identical(other.schoolYear, schoolYear) ||
                other.schoolYear == schoolYear) &&
            (identical(other.totalLogCount, totalLogCount) ||
                other.totalLogCount == totalLogCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalHours,
      const DeepCollectionEquality().hash(_students),
      schoolYear,
      totalLogCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyStatsImplCopyWith<_$FamilyStatsImpl> get copyWith =>
      __$$FamilyStatsImplCopyWithImpl<_$FamilyStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyStatsImplToJson(
      this,
    );
  }
}

abstract class _FamilyStats implements FamilyStats {
  const factory _FamilyStats(
      {required final double totalHours,
      required final List<StudentStats> students,
      required final String schoolYear,
      required final int totalLogCount}) = _$FamilyStatsImpl;

  factory _FamilyStats.fromJson(Map<String, dynamic> json) =
      _$FamilyStatsImpl.fromJson;

  @override
  double get totalHours;
  @override
  List<StudentStats> get students;
  @override
  String get schoolYear;
  @override
  int get totalLogCount;
  @override
  @JsonKey(ignore: true)
  _$$FamilyStatsImplCopyWith<_$FamilyStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
