// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentImpl _$$StudentImplFromJson(Map<String, dynamic> json) =>
    _$StudentImpl(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      name: json['name'] as String,
      gradeLevel: json['gradeLevel'] as String,
      userId: json['userId'] as String?,
      avatarColor: json['avatarColor'] as String?,
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$StudentImplToJson(_$StudentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'name': instance.name,
      'gradeLevel': instance.gradeLevel,
      'userId': instance.userId,
      'avatarColor': instance.avatarColor,
      'active': instance.active,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
