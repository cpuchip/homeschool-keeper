import 'package:flutter_test/flutter_test.dart';
import 'package:homeschool_keeper/core/sync/conflict_item.dart';

void main() {
  group('ConflictItem', () {
    test('creates conflict item with all properties', () {
      final conflict = ConflictItem(
        entityType: ConflictEntityType.student,
        entityId: 'local-123',
        remoteId: 'remote-456',
        displayName: 'John Smith',
        localUpdatedAt: DateTime(2024, 1, 15, 10, 30),
        serverUpdatedAt: DateTime(2024, 1, 15, 10, 35),
        localData: {'name': 'John Smith', 'gradeLevel': '5th'},
        serverData: {'name': 'John Doe', 'gradeLevel': '5th'},
        fieldDiffs: [
          const FieldDiff(
            fieldName: 'name',
            displayName: 'Name',
            localValue: 'John Smith',
            serverValue: 'John Doe',
          ),
        ],
      );

      expect(conflict.entityType, ConflictEntityType.student);
      expect(conflict.entityId, 'local-123');
      expect(conflict.remoteId, 'remote-456');
      expect(conflict.displayName, 'John Smith');
      expect(conflict.entityTypeName, 'Student');
      expect(conflict.hasFieldDifferences, true);
      expect(conflict.fieldDiffs.length, 1);
    });

    test('entityTypeName returns correct strings', () {
      expect(
        ConflictItem(
          entityType: ConflictEntityType.student,
          entityId: '',
          remoteId: '',
          displayName: '',
          localUpdatedAt: DateTime.now(),
          serverUpdatedAt: DateTime.now(),
          localData: const {},
          serverData: const {},
          fieldDiffs: const [],
        ).entityTypeName,
        'Student',
      );

      expect(
        ConflictItem(
          entityType: ConflictEntityType.subject,
          entityId: '',
          remoteId: '',
          displayName: '',
          localUpdatedAt: DateTime.now(),
          serverUpdatedAt: DateTime.now(),
          localData: const {},
          serverData: const {},
          fieldDiffs: const [],
        ).entityTypeName,
        'Subject',
      );

      expect(
        ConflictItem(
          entityType: ConflictEntityType.log,
          entityId: '',
          remoteId: '',
          displayName: '',
          localUpdatedAt: DateTime.now(),
          serverUpdatedAt: DateTime.now(),
          localData: const {},
          serverData: const {},
          fieldDiffs: const [],
        ).entityTypeName,
        'Log Entry',
      );
    });

    test('hasFieldDifferences returns false when no diffs', () {
      final conflict = ConflictItem(
        entityType: ConflictEntityType.student,
        entityId: 'local-123',
        remoteId: 'remote-456',
        displayName: 'John Smith',
        localUpdatedAt: DateTime.now(),
        serverUpdatedAt: DateTime.now(),
        localData: const {},
        serverData: const {},
        fieldDiffs: const [],
      );

      expect(conflict.hasFieldDifferences, false);
    });
  });

  group('FieldDiff', () {
    test('hasDifference returns true when values differ', () {
      const diff = FieldDiff(
        fieldName: 'name',
        displayName: 'Name',
        localValue: 'John',
        serverValue: 'Jane',
      );

      expect(diff.hasDifference, true);
    });

    test('hasDifference returns false when values are equal', () {
      const diff = FieldDiff(
        fieldName: 'name',
        displayName: 'Name',
        localValue: 'John',
        serverValue: 'John',
      );

      expect(diff.hasDifference, false);
    });

    test('hasDifference handles null values', () {
      const diff1 = FieldDiff(
        fieldName: 'color',
        displayName: 'Color',
        localValue: null,
        serverValue: 'blue',
      );
      expect(diff1.hasDifference, true);

      const diff2 = FieldDiff(
        fieldName: 'color',
        displayName: 'Color',
        localValue: null,
        serverValue: null,
      );
      expect(diff2.hasDifference, false);
    });
  });

  group('createStudentFieldDiffs', () {
    test('returns only fields that differ', () {
      final diffs = createStudentFieldDiffs(
        localName: 'John',
        serverName: 'Jane',
        localGradeLevel: '5th',
        serverGradeLevel: '5th',
        localAvatarColor: null,
        serverAvatarColor: null,
        localActive: true,
        serverActive: true,
      );

      expect(diffs.length, 1);
      expect(diffs[0].fieldName, 'name');
      expect(diffs[0].localValue, 'John');
      expect(diffs[0].serverValue, 'Jane');
    });

    test('returns empty list when all fields match', () {
      final diffs = createStudentFieldDiffs(
        localName: 'John',
        serverName: 'John',
        localGradeLevel: '5th',
        serverGradeLevel: '5th',
        localAvatarColor: 'blue',
        serverAvatarColor: 'blue',
        localActive: true,
        serverActive: true,
      );

      expect(diffs, isEmpty);
    });
  });

  group('createSubjectFieldDiffs', () {
    test('returns only fields that differ', () {
      final diffs = createSubjectFieldDiffs(
        localName: 'Math',
        serverName: 'Math',
        localType: 'core',
        serverType: 'elective',
        localTargetHours: 100.0,
        serverTargetHours: 100.0,
        localColor: '#FF0000',
        serverColor: '#FF0000',
        localSortOrder: 1,
        serverSortOrder: 1,
        localActive: true,
        serverActive: true,
      );

      expect(diffs.length, 1);
      expect(diffs[0].fieldName, 'type');
      expect(diffs[0].localValue, 'core');
      expect(diffs[0].serverValue, 'elective');
    });
  });

  group('createLogFieldDiffs', () {
    test('returns only fields that differ', () {
      final diffs = createLogFieldDiffs(
        localStudentName: 'John',
        serverStudentName: 'John',
        localSubjectName: 'Math',
        serverSubjectName: 'Math',
        localDate: DateTime(2024, 1, 15),
        serverDate: DateTime(2024, 1, 15),
        localHours: 1.5,
        serverHours: 2.0,
        localDescription: 'Test',
        serverDescription: 'Test',
        localLocationType: 'home',
        serverLocationType: 'home',
        localLocationName: null,
        serverLocationName: null,
      );

      expect(diffs.length, 1);
      expect(diffs[0].fieldName, 'hours');
      expect(diffs[0].localValue, 1.5);
      expect(diffs[0].serverValue, 2.0);
    });
  });

  group('ResolvedConflict', () {
    test('stores conflict and resolution', () {
      final conflict = ConflictItem(
        entityType: ConflictEntityType.student,
        entityId: 'local-123',
        remoteId: 'remote-456',
        displayName: 'John Smith',
        localUpdatedAt: DateTime.now(),
        serverUpdatedAt: DateTime.now(),
        localData: const {},
        serverData: const {},
        fieldDiffs: const [],
      );

      final resolved = ResolvedConflict(
        conflict: conflict,
        resolution: ConflictResolution.keepLocal,
      );

      expect(resolved.conflict, conflict);
      expect(resolved.resolution, ConflictResolution.keepLocal);
    });
  });
}
