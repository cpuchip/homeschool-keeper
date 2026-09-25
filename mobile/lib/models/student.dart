import 'package:freezed_annotation/freezed_annotation.dart';

part 'student.freezed.dart';
part 'student.g.dart';

/// Student model representing a homeschool student
@freezed
class Student with _$Student {
  const factory Student({
    required String id,
    required String familyId,
    required String name,
    required String gradeLevel,
    String? userId,
    String? avatarColor,
    required bool active,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
}

/// Grade levels
class GradeLevels {
  static const List<String> all = [
    'K', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12',
  ];
}

/// Avatar colors for students
class AvatarColors {
  static const List<String> all = [
    '#3B82F6', // blue
    '#10B981', // green
    '#F59E0B', // amber
    '#EF4444', // red
    '#8B5CF6', // purple
    '#EC4899', // pink
    '#06B6D4', // cyan
    '#F97316', // orange
  ];
}
