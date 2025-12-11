import '../core/database/database_service.dart';
import '../core/database/hive_entities.dart';
import '../models/log_entry.dart';

/// Local repository for LogEntry data using Hive
class LogEntryRepository {
  final DatabaseService _db;

  LogEntryRepository({DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  /// Get all log entries for the current school year
  List<LogEntry> getAll() {
    final currentYear = _db.familySettings.currentSchoolYear;
    return _db.logEntriesBox.values
        .where((l) => l.schoolYear == currentYear)
        .map(_toModel)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  /// Get all log entries for a specific school year
  List<LogEntry> getBySchoolYear(String schoolYear) {
    return _db.logEntriesBox.values
        .where((l) => l.schoolYear == schoolYear)
        .map(_toModel)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get all log entries (all years)
  List<LogEntry> getAllYears() {
    return _db.logEntriesBox.values.map(_toModel).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get log entries for a specific student
  List<LogEntry> getByStudent(String studentId, {String? schoolYear}) {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    return _db.logEntriesBox.values
        .where((l) => l.studentId == studentId && l.schoolYear == year)
        .map(_toModel)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get log entries for a specific subject
  List<LogEntry> getBySubject(String subjectId, {String? schoolYear}) {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    return _db.logEntriesBox.values
        .where((l) => l.subjectId == subjectId && l.schoolYear == year)
        .map(_toModel)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get log entries for a specific date range
  List<LogEntry> getByDateRange(
    DateTime start,
    DateTime end, {
    String? studentId,
  }) {
    var logs = _db.logEntriesBox.values.where(
      (l) =>
          l.date.isAfter(start.subtract(const Duration(days: 1))) &&
          l.date.isBefore(end.add(const Duration(days: 1))),
    );

    if (studentId != null) {
      logs = logs.where((l) => l.studentId == studentId);
    }

    return logs.map(_toModel).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get recent log entries (last 7 days)
  List<LogEntry> getRecent({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _db.logEntriesBox.values
        .where((l) => l.date.isAfter(cutoff))
        .map(_toModel)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get a log entry by ID
  LogEntry? getById(String id) {
    final entity = _db.logEntriesBox.get(id);
    return entity != null ? _toModel(entity) : null;
  }

  /// Count log entries for a specific subject (all school years)
  int countBySubject(String subjectId) {
    return _db.logEntriesBox.values
        .where((l) => l.subjectId == subjectId)
        .length;
  }

  /// Count log entries for a specific student (all school years)
  int countByStudent(String studentId) {
    return _db.logEntriesBox.values
        .where((l) => l.studentId == studentId)
        .length;
  }

  /// Create a new log entry
  Future<LogEntry> create({
    required String studentId,
    required String subjectId,
    required DateTime date,
    required double hours,
    required String description,
    String locationType = 'home',
    String? locationId,
    String? locationName,
    String? groupId,
  }) async {
    // Validate hours increment
    final increment = _db.familySettings.hourIncrement;
    final roundedHours = (hours / increment).round() * increment;

    final entity = LogEntryEntity.create(
      studentId: studentId,
      subjectId: subjectId,
      date: date,
      hours: roundedHours,
      description: description,
      locationType: locationType,
      locationId: locationId,
      locationName: locationName,
      groupId: groupId,
    );

    await _db.logEntriesBox.put(entity.id, entity);
    return _toModel(entity);
  }

  /// Update a log entry
  Future<LogEntry> update(
    String id, {
    String? studentId,
    String? subjectId,
    DateTime? date,
    double? hours,
    String? description,
    String? locationType,
    String? locationId,
    String? locationName,
    String? status,
  }) async {
    final entity = _db.logEntriesBox.get(id);
    if (entity == null) {
      throw Exception('Log entry not found: $id');
    }

    if (studentId != null) entity.studentId = studentId;
    if (subjectId != null) entity.subjectId = subjectId;
    if (date != null) entity.date = date;
    if (hours != null) {
      final increment = _db.familySettings.hourIncrement;
      entity.hours = (hours / increment).round() * increment;
    }
    if (description != null) entity.description = description;
    if (locationType != null) entity.locationType = locationType;
    if (locationId != null) entity.locationId = locationId;
    if (locationName != null) entity.locationName = locationName;
    if (status != null) entity.status = status;
    entity.updatedAt = DateTime.now();
    entity.needsSync = true;

    await entity.save();
    return _toModel(entity);
  }

  /// Delete a log entry (hard delete)
  Future<void> delete(String id) async {
    await _db.logEntriesBox.delete(id);
  }

  /// Get total hours for a student in the current school year
  double getTotalHours(String studentId, {String? schoolYear}) {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    return _db.logEntriesBox.values
        .where((l) => l.studentId == studentId && l.schoolYear == year)
        .fold(0.0, (sum, l) => sum + l.hours);
  }

  /// Get total hours by subject for a student
  Map<String, double> getHoursBySubject(
    String studentId, {
    String? schoolYear,
  }) {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    final logs = _db.logEntriesBox.values
        .where((l) => l.studentId == studentId && l.schoolYear == year);

    final hoursBySubject = <String, double>{};
    for (final log in logs) {
      hoursBySubject[log.subjectId] =
          (hoursBySubject[log.subjectId] ?? 0) + log.hours;
    }
    return hoursBySubject;
  }

  /// Get all unique school years with log entries
  List<String> getSchoolYears() {
    final years =
        _db.logEntriesBox.values.map((l) => l.schoolYear).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Newest first
    return years;
  }

  /// Get log entries that need syncing
  List<LogEntryEntity> getPendingSync() {
    return _db.logEntriesBox.values.where((l) => l.needsSync).toList();
  }

  /// Mark a log entry as synced
  Future<void> markSynced(String id, String remoteId) async {
    final entity = _db.logEntriesBox.get(id);
    if (entity != null) {
      entity.remoteId = remoteId;
      entity.needsSync = false;
      entity.lastSyncedAt = DateTime.now();
      await entity.save();
    }
  }

  /// Import a log entry from remote
  Future<void> importFromRemote(Map<String, dynamic> json) async {
    final entity = LogEntryEntity.fromJson(json);
    entity.needsSync = false;
    entity.lastSyncedAt = DateTime.now();
    entity.remoteId = json['id'] as String;
    await _db.logEntriesBox.put(entity.id, entity);
  }

  /// Convert entity to model
  LogEntry _toModel(LogEntryEntity entity) {
    return LogEntry(
      id: entity.id,
      familyId: entity.familyId,
      organizationId: entity.organizationId,
      studentId: entity.studentId,
      subjectId: entity.subjectId,
      groupId: entity.groupId,
      date: entity.date,
      hours: entity.hours,
      description: entity.description,
      locationType: entity.locationType,
      locationId: entity.locationId,
      locationName: entity.locationName,
      submittedBy: entity.submittedBy,
      status: entity.status,
      schoolYear: entity.schoolYear,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
