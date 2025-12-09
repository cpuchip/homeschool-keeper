// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LogEntryImpl _$$LogEntryImplFromJson(Map<String, dynamic> json) =>
    _$LogEntryImpl(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      organizationId: json['organizationId'] as String?,
      studentId: json['studentId'] as String,
      subjectId: json['subjectId'] as String,
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num).toDouble(),
      description: json['description'] as String,
      locationType: json['locationType'] as String,
      locationId: json['locationId'] as String?,
      locationName: json['locationName'] as String?,
      submittedBy: json['submittedBy'] as String,
      status: json['status'] as String,
      schoolYear: json['schoolYear'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$LogEntryImplToJson(_$LogEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'organizationId': instance.organizationId,
      'studentId': instance.studentId,
      'subjectId': instance.subjectId,
      'date': instance.date.toIso8601String(),
      'hours': instance.hours,
      'description': instance.description,
      'locationType': instance.locationType,
      'locationId': instance.locationId,
      'locationName': instance.locationName,
      'submittedBy': instance.submittedBy,
      'status': instance.status,
      'schoolYear': instance.schoolYear,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
