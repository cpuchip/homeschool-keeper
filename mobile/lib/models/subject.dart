import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject.freezed.dart';
part 'subject.g.dart';

/// Subject model representing a course that hours can be logged against
@freezed
class Subject with _$Subject {
  const factory Subject({
    required String id,
    required String familyId,
    required String name,
    required String type, // core, elective
    double? targetHours,
    required String color,
    required bool isDefault,
    required int sortOrder,
    required bool active,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Subject;

  factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);
}

/// Subject types
class SubjectType {
  static const String core = 'core';
  static const String elective = 'elective';
}

/// Subject colors for UI
class SubjectColors {
  static const List<String> all = [
    '#3B82F6', // blue
    '#10B981', // green
    '#F59E0B', // amber
    '#EF4444', // red
    '#8B5CF6', // purple
    '#EC4899', // pink
    '#06B6D4', // cyan
    '#F97316', // orange
    '#84CC16', // lime
    '#6366F1', // indigo
  ];
}
