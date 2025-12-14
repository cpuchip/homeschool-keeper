// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubjectImpl _$$SubjectImplFromJson(Map<String, dynamic> json) =>
    _$SubjectImpl(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      targetHours: (json['targetHours'] as num?)?.toDouble(),
      color: json['color'] as String,
      isDefault: json['isDefault'] as bool,
      sortOrder: (json['sortOrder'] as num).toInt(),
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$SubjectImplToJson(_$SubjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'name': instance.name,
      'type': instance.type,
      'targetHours': instance.targetHours,
      'color': instance.color,
      'isDefault': instance.isDefault,
      'sortOrder': instance.sortOrder,
      'active': instance.active,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
