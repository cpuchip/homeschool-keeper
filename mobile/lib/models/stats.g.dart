// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubjectHoursImpl _$$SubjectHoursImplFromJson(Map<String, dynamic> json) =>
    _$SubjectHoursImpl(
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      color: json['color'] as String,
      hours: (json['hours'] as num).toDouble(),
      targetHours: (json['targetHours'] as num?)?.toDouble(),
      progress: (json['progress'] as num).toDouble(),
    );

Map<String, dynamic> _$$SubjectHoursImplToJson(_$SubjectHoursImpl instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'color': instance.color,
      'hours': instance.hours,
      'targetHours': instance.targetHours,
      'progress': instance.progress,
    };

_$StudentStatsImpl _$$StudentStatsImplFromJson(Map<String, dynamic> json) =>
    _$StudentStatsImpl(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      totalHours: (json['totalHours'] as num).toDouble(),
      hoursBySubject: (json['hoursBySubject'] as List<dynamic>)
          .map((e) => SubjectHours.fromJson(e as Map<String, dynamic>))
          .toList(),
      logCount: (json['logCount'] as num).toInt(),
      schoolYear: json['schoolYear'] as String,
    );

Map<String, dynamic> _$$StudentStatsImplToJson(_$StudentStatsImpl instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'totalHours': instance.totalHours,
      'hoursBySubject': instance.hoursBySubject,
      'logCount': instance.logCount,
      'schoolYear': instance.schoolYear,
    };

_$FamilyStatsImpl _$$FamilyStatsImplFromJson(Map<String, dynamic> json) =>
    _$FamilyStatsImpl(
      totalHours: (json['totalHours'] as num).toDouble(),
      students: (json['students'] as List<dynamic>)
          .map((e) => StudentStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      schoolYear: json['schoolYear'] as String,
      totalLogCount: (json['totalLogCount'] as num).toInt(),
    );

Map<String, dynamic> _$$FamilyStatsImplToJson(_$FamilyStatsImpl instance) =>
    <String, dynamic>{
      'totalHours': instance.totalHours,
      'students': instance.students,
      'schoolYear': instance.schoolYear,
      'totalLogCount': instance.totalLogCount,
    };
