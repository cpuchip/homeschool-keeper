import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats.freezed.dart';
part 'stats.g.dart';

/// Subject hours breakdown for stats
@freezed
class SubjectHours with _$SubjectHours {
  const factory SubjectHours({
    required String subjectId,
    required String subjectName,
    required String color,
    required double hours,
    double? targetHours,
    required double progress, // 0-100 percentage
  }) = _SubjectHours;

  factory SubjectHours.fromJson(Map<String, dynamic> json) =>
      _$SubjectHoursFromJson(json);
}

/// Student statistics response
@freezed
class StudentStats with _$StudentStats {
  const factory StudentStats({
    required String studentId,
    required String studentName,
    required double totalHours,
    required List<SubjectHours> hoursBySubject,
    required int logCount,
    required String schoolYear,
  }) = _StudentStats;

  factory StudentStats.fromJson(Map<String, dynamic> json) =>
      _$StudentStatsFromJson(json);
}

/// Family-wide statistics response
@freezed
class FamilyStats with _$FamilyStats {
  const factory FamilyStats({
    required double totalHours,
    required List<StudentStats> students,
    required String schoolYear,
    required int totalLogCount,
  }) = _FamilyStats;

  factory FamilyStats.fromJson(Map<String, dynamic> json) =>
      _$FamilyStatsFromJson(json);
}
