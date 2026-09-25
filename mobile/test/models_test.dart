import 'package:flutter_test/flutter_test.dart';

import 'package:homeschool_keeper/models/student.dart';
import 'package:homeschool_keeper/models/log_entry.dart';
import 'package:homeschool_keeper/models/subject.dart';
import 'package:homeschool_keeper/core/utils/logger.dart';

void main() {
  group('Student Model', () {
    test('creates student from JSON', () {
      final json = {
        'id': 'test-id',
        'familyId': 'family-id',
        'name': 'Test Student',
        'gradeLevel': '5th Grade',
        'active': true,
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      };

      final student = Student.fromJson(json);

      expect(student.id, 'test-id');
      expect(student.name, 'Test Student');
      expect(student.gradeLevel, '5th Grade');
      expect(student.active, true);
    });

    test('converts student to JSON', () {
      final student = Student(
        id: 'test-id',
        familyId: 'family-id',
        name: 'Test Student',
        gradeLevel: '5th Grade',
        active: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = student.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Test Student');
    });
  });

  group('Subject Model', () {
    test('creates subject from JSON', () {
      final json = {
        'id': 'sub-id',
        'familyId': 'family-id',
        'name': 'Math',
        'type': 'core',
        'color': '#FF0000',
        'isDefault': true,
        'sortOrder': 0,
        'active': true,
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      };

      final subject = Subject.fromJson(json);

      expect(subject.id, 'sub-id');
      expect(subject.name, 'Math');
      expect(subject.type, 'core');
      expect(subject.type == SubjectType.core, true);
    });

    test('SubjectType constants are correct', () {
      expect(SubjectType.core, 'core');
      expect(SubjectType.elective, 'elective');
    });

    test('SubjectColors has 10 colors', () {
      expect(SubjectColors.all.length, 10);
    });
  });

  group('LogEntry Model', () {
    test('creates log entry from JSON', () {
      final json = {
        'id': 'log-id',
        'familyId': 'family-id',
        'studentId': 'student-id',
        'subjectId': 'subject-id',
        'date': '2024-01-15',
        'hours': 2.5,
        'description': 'Test log',
        'locationType': 'home',
        'submittedBy': 'user-id',
        'status': 'approved',
        'schoolYear': '2024-2025',
        'createdAt': '2024-01-15T10:00:00Z',
        'updatedAt': '2024-01-15T10:00:00Z',
      };

      final log = LogEntry.fromJson(json);

      expect(log.id, 'log-id');
      expect(log.hours, 2.5);
      expect(log.description, 'Test log');
      expect(log.locationType, 'home');
    });

    test('converts log entry to JSON', () {
      final log = LogEntry(
        id: 'log-id',
        familyId: 'family-id',
        studentId: 'student-id',
        subjectId: 'subject-id',
        date: DateTime(2024, 1, 15),
        hours: 2.5,
        description: 'Test log',
        locationType: 'home',
        submittedBy: 'user-id',
        status: 'approved',
        schoolYear: '2024-2025',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = log.toJson();

      expect(json['studentId'], 'student-id');
      expect(json['subjectId'], 'subject-id');
      expect(json['hours'], 2.5);
    });
  });

  group('LocationType constants', () {
    test('has correct values', () {
      expect(LocationType.home, 'home');
      expect(LocationType.fieldTrip, 'field_trip');
      expect(LocationType.coOp, 'co_op');
      expect(LocationType.online, 'online');
      expect(LocationType.other, 'other');
    });

    test('displayName returns correct names', () {
      expect(LocationType.displayName('home'), 'Home');
      expect(LocationType.displayName('field_trip'), 'Field Trip');
      expect(LocationType.displayName('co_op'), 'Co-Op');
    });
  });

  group('Logger Utility', () {
    test('Log categories exist', () {
      expect(Log.auth, isNotNull);
      expect(Log.api, isNotNull);
      expect(Log.sync, isNotNull);
    });
  });
}
