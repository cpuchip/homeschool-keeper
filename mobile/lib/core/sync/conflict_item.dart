/// Model for tracking sync conflicts with local and server versions
/// Used for Windows Explorer-style conflict resolution UI
library;

/// Types of entities that can have conflicts
enum ConflictEntityType {
  student,
  subject,
  log,
}

/// Represents a single field difference between local and server versions
class FieldDiff {
  final String fieldName;
  final String displayName;
  final dynamic localValue;
  final dynamic serverValue;

  const FieldDiff({
    required this.fieldName,
    required this.displayName,
    required this.localValue,
    required this.serverValue,
  });

  bool get hasDifference => localValue != serverValue;

  @override
  String toString() =>
      'FieldDiff($displayName: local=$localValue, server=$serverValue)';
}

/// Represents a sync conflict between local and server versions
class ConflictItem {
  final ConflictEntityType entityType;
  final String entityId;
  final String remoteId;
  final String displayName;
  final DateTime localUpdatedAt;
  final DateTime serverUpdatedAt;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final List<FieldDiff> fieldDiffs;

  const ConflictItem({
    required this.entityType,
    required this.entityId,
    required this.remoteId,
    required this.displayName,
    required this.localUpdatedAt,
    required this.serverUpdatedAt,
    required this.localData,
    required this.serverData,
    required this.fieldDiffs,
  });

  /// Get the type as a user-friendly string
  String get entityTypeName {
    switch (entityType) {
      case ConflictEntityType.student:
        return 'Student';
      case ConflictEntityType.subject:
        return 'Subject';
      case ConflictEntityType.log:
        return 'Log Entry';
    }
  }

  /// Check if there are actual field differences
  bool get hasFieldDifferences => fieldDiffs.any((d) => d.hasDifference);

  @override
  String toString() =>
      'ConflictItem($entityTypeName: $displayName, ${fieldDiffs.length} diffs)';
}

/// User's resolution choice for a conflict
enum ConflictResolution {
  /// Keep the local version, push to server
  keepLocal,

  /// Keep the server version, overwrite local
  keepServer,

  /// Keep both (create duplicate with merged data - not always possible)
  keepBoth,

  /// Skip this conflict for now
  skip,
}

/// Result of a resolved conflict
class ResolvedConflict {
  final ConflictItem conflict;
  final ConflictResolution resolution;

  const ResolvedConflict({
    required this.conflict,
    required this.resolution,
  });
}

/// Helper to create field diffs for students
List<FieldDiff> createStudentFieldDiffs({
  required String localName,
  required String serverName,
  required String localGradeLevel,
  required String serverGradeLevel,
  required String? localAvatarColor,
  required String? serverAvatarColor,
  required bool localActive,
  required bool serverActive,
}) {
  return [
    FieldDiff(
      fieldName: 'name',
      displayName: 'Name',
      localValue: localName,
      serverValue: serverName,
    ),
    FieldDiff(
      fieldName: 'gradeLevel',
      displayName: 'Grade Level',
      localValue: localGradeLevel,
      serverValue: serverGradeLevel,
    ),
    FieldDiff(
      fieldName: 'avatarColor',
      displayName: 'Avatar Color',
      localValue: localAvatarColor,
      serverValue: serverAvatarColor,
    ),
    FieldDiff(
      fieldName: 'active',
      displayName: 'Active',
      localValue: localActive,
      serverValue: serverActive,
    ),
  ].where((d) => d.hasDifference).toList();
}

/// Helper to create field diffs for subjects
List<FieldDiff> createSubjectFieldDiffs({
  required String localName,
  required String serverName,
  required String localType,
  required String serverType,
  required double? localTargetHours,
  required double? serverTargetHours,
  required String localColor,
  required String serverColor,
  required int localSortOrder,
  required int serverSortOrder,
  required bool localActive,
  required bool serverActive,
}) {
  return [
    FieldDiff(
      fieldName: 'name',
      displayName: 'Name',
      localValue: localName,
      serverValue: serverName,
    ),
    FieldDiff(
      fieldName: 'type',
      displayName: 'Type',
      localValue: localType,
      serverValue: serverType,
    ),
    FieldDiff(
      fieldName: 'targetHours',
      displayName: 'Target Hours',
      localValue: localTargetHours,
      serverValue: serverTargetHours,
    ),
    FieldDiff(
      fieldName: 'color',
      displayName: 'Color',
      localValue: localColor,
      serverValue: serverColor,
    ),
    FieldDiff(
      fieldName: 'sortOrder',
      displayName: 'Sort Order',
      localValue: localSortOrder,
      serverValue: serverSortOrder,
    ),
    FieldDiff(
      fieldName: 'active',
      displayName: 'Active',
      localValue: localActive,
      serverValue: serverActive,
    ),
  ].where((d) => d.hasDifference).toList();
}

/// Helper to create field diffs for log entries
List<FieldDiff> createLogFieldDiffs({
  required String localStudentName,
  required String serverStudentName,
  required String localSubjectName,
  required String serverSubjectName,
  required DateTime localDate,
  required DateTime serverDate,
  required double localHours,
  required double serverHours,
  required String localDescription,
  required String serverDescription,
  required String localLocationType,
  required String serverLocationType,
  required String? localLocationName,
  required String? serverLocationName,
}) {
  return [
    FieldDiff(
      fieldName: 'studentName',
      displayName: 'Student',
      localValue: localStudentName,
      serverValue: serverStudentName,
    ),
    FieldDiff(
      fieldName: 'subjectName',
      displayName: 'Subject',
      localValue: localSubjectName,
      serverValue: serverSubjectName,
    ),
    FieldDiff(
      fieldName: 'date',
      displayName: 'Date',
      localValue: _formatDate(localDate),
      serverValue: _formatDate(serverDate),
    ),
    FieldDiff(
      fieldName: 'hours',
      displayName: 'Hours',
      localValue: localHours,
      serverValue: serverHours,
    ),
    FieldDiff(
      fieldName: 'description',
      displayName: 'Description',
      localValue: localDescription,
      serverValue: serverDescription,
    ),
    FieldDiff(
      fieldName: 'locationType',
      displayName: 'Location Type',
      localValue: localLocationType,
      serverValue: serverLocationType,
    ),
    FieldDiff(
      fieldName: 'locationName',
      displayName: 'Location Name',
      localValue: localLocationName,
      serverValue: serverLocationName,
    ),
  ].where((d) => d.hasDifference).toList();
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
