import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../constants.dart';
import '../database/database_service.dart';
import '../database/hive_entities.dart';

/// Sync status for tracking progress
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? error;
  final int pushedStudents;
  final int pushedSubjects;
  final int pushedLogs;
  final int pulledStudents;
  final int pulledSubjects;
  final int pulledLogs;
  final DateTime syncedAt;

  SyncResult({
    required this.success,
    this.error,
    this.pushedStudents = 0,
    this.pushedSubjects = 0,
    this.pushedLogs = 0,
    this.pulledStudents = 0,
    this.pulledSubjects = 0,
    this.pulledLogs = 0,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory SyncResult.error(String message) {
    return SyncResult(success: false, error: message);
  }

  factory SyncResult.success({
    int pushedStudents = 0,
    int pushedSubjects = 0,
    int pushedLogs = 0,
    int pulledStudents = 0,
    int pulledSubjects = 0,
    int pulledLogs = 0,
  }) {
    return SyncResult(
      success: true,
      pushedStudents: pushedStudents,
      pushedSubjects: pushedSubjects,
      pushedLogs: pushedLogs,
      pulledStudents: pulledStudents,
      pulledSubjects: pulledSubjects,
      pulledLogs: pulledLogs,
    );
  }

  int get totalPushed => pushedStudents + pushedSubjects + pushedLogs;
  int get totalPulled => pulledStudents + pulledSubjects + pulledLogs;
}

/// Sync service for pushing/pulling data between Hive and server
/// 
/// Sync strategy:
/// 1. Push local changes (needsSync=true) to server first
/// 2. Pull all server data and merge with local
/// 3. Conflict resolution: Server wins (last-write-wins based on updatedAt)
class SyncService {
  final ApiClient _apiClient;
  final DatabaseService _db;
  
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;
  
  String? _lastError;
  String? get lastError => _lastError;

  SyncService(this._apiClient, {DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  /// Perform a full sync (push local changes, pull server data)
  Future<SyncResult> performFullSync() async {
    if (_status == SyncStatus.syncing) {
      debugPrint('[Sync] Already syncing, skipping');
      return SyncResult.error('Sync already in progress');
    }

    debugPrint('[Sync] Starting full sync...');
    _status = SyncStatus.syncing;
    _lastError = null;

    try {
      // Push local changes first
      debugPrint('[Sync] Pushing local changes...');
      final pushResult = await _pushLocalChanges();
      debugPrint('[Sync] Pushed: ${pushResult.students} students, ${pushResult.subjects} subjects, ${pushResult.logs} logs');
      
      // Then pull server data
      debugPrint('[Sync] Pulling server data...');
      final pullResult = await _pullServerData();
      debugPrint('[Sync] Pulled: ${pullResult.students} students, ${pullResult.subjects} subjects, ${pullResult.logs} logs');

      // Update sync metadata
      await _updateSyncMeta();

      _status = SyncStatus.success;
      debugPrint('[Sync] Full sync completed successfully!');
      
      return SyncResult.success(
        pushedStudents: pushResult.students,
        pushedSubjects: pushResult.subjects,
        pushedLogs: pushResult.logs,
        pulledStudents: pullResult.students,
        pulledSubjects: pullResult.subjects,
        pulledLogs: pullResult.logs,
      );
    } catch (e, stack) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      debugPrint('[Sync] Error: $e');
      debugPrint('[Sync] Stack: $stack');
      return SyncResult.error(e.toString());
    }
  }

  /// Push only - for quick saves when online
  Future<SyncResult> pushChanges() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult.error('Sync already in progress');
    }

    _status = SyncStatus.syncing;
    _lastError = null;

    try {
      final result = await _pushLocalChanges();
      _status = SyncStatus.success;
      
      return SyncResult.success(
        pushedStudents: result.students,
        pushedSubjects: result.subjects,
        pushedLogs: result.logs,
      );
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      return SyncResult.error(e.toString());
    }
  }

  /// Pull only - for refreshing from server
  Future<SyncResult> pullData() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult.error('Sync already in progress');
    }

    _status = SyncStatus.syncing;
    _lastError = null;

    try {
      final result = await _pullServerData();
      await _updateSyncMeta();
      _status = SyncStatus.success;
      
      return SyncResult.success(
        pulledStudents: result.students,
        pulledSubjects: result.subjects,
        pulledLogs: result.logs,
      );
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      return SyncResult.error(e.toString());
    }
  }

  /// Push local changes to server
  Future<_PushPullCounts> _pushLocalChanges() async {
    int students = 0;
    int subjects = 0;
    int logs = 0;

    // Push students
    final pendingStudents = _db.studentsBox.values
        .where((s) => s.needsSync)
        .toList();
    
    for (final student in pendingStudents) {
      try {
        if (student.remoteId != null) {
          // Update existing
          await _updateStudentOnServer(student);
        } else {
          // Create new
          await _createStudentOnServer(student);
        }
        students++;
      } catch (e) {
        debugPrint('Failed to sync student ${student.id}: $e');
        // Continue with other items, don't fail entire sync
      }
    }

    // Push subjects (including defaults - they need remoteIds for log sync)
    final pendingSubjects = _db.subjectsBox.values
        .where((s) => s.needsSync)
        .toList();
    
    for (final subject in pendingSubjects) {
      try {
        if (subject.remoteId != null) {
          await _updateSubjectOnServer(subject);
        } else {
          await _createSubjectOnServer(subject);
        }
        subjects++;
      } catch (e) {
        debugPrint('Failed to sync subject ${subject.id}: $e');
      }
    }

    // Push log entries
    final pendingLogs = _db.logEntriesBox.values
        .where((l) => l.needsSync)
        .toList();
    
    for (final log in pendingLogs) {
      try {
        if (log.remoteId != null) {
          await _updateLogOnServer(log);
        } else {
          await _createLogOnServer(log);
        }
        logs++;
      } catch (e) {
        debugPrint('Failed to sync log ${log.id}: $e');
      }
    }

    return _PushPullCounts(students: students, subjects: subjects, logs: logs);
  }

  /// Pull server data and merge with local
  Future<_PushPullCounts> _pullServerData() async {
    int students = 0;
    int subjects = 0;
    int logs = 0;

    // Pull students
    try {
      final response = await _apiClient.get(ApiConstants.students);
      final serverStudents = (response.data as List<dynamic>?) ?? [];
      
      for (final json in serverStudents) {
        await _mergeStudent(json as Map<String, dynamic>);
        students++;
      }
    } catch (e) {
      debugPrint('Failed to pull students: $e');
      rethrow;
    }

    // Pull subjects
    try {
      final response = await _apiClient.get(ApiConstants.subjects);
      final serverSubjects = (response.data as List<dynamic>?) ?? [];
      
      for (final json in serverSubjects) {
        await _mergeSubject(json as Map<String, dynamic>);
        subjects++;
      }
    } catch (e) {
      debugPrint('Failed to pull subjects: $e');
      rethrow;
    }

    // Pull logs
    try {
      final response = await _apiClient.get(ApiConstants.logs);
      // Logs endpoint returns {logs: [...], total: N, page: N, limit: N}
      final data = response.data as Map<String, dynamic>?;
      final serverLogs = (data?['logs'] as List<dynamic>?) ?? [];
      
      for (final json in serverLogs) {
        await _mergeLog(json as Map<String, dynamic>);
        logs++;
      }
    } catch (e) {
      debugPrint('Failed to pull logs: $e');
      rethrow;
    }

    return _PushPullCounts(students: students, subjects: subjects, logs: logs);
  }

  // === Student sync helpers ===

  Future<void> _createStudentOnServer(StudentEntity student) async {
    final response = await _apiClient.post(
      ApiConstants.students,
      data: {
        'name': student.name,
        'gradeLevel': student.gradeLevel,
        'avatarColor': student.avatarColor,
      },
    );
    
    final serverId = response.data['id'] as String;
    student.remoteId = serverId;
    student.familyId = response.data['familyId'] as String;
    student.needsSync = false;
    student.lastSyncedAt = DateTime.now();
    await student.save();
  }

  Future<void> _updateStudentOnServer(StudentEntity student) async {
    await _apiClient.patch(
      '${ApiConstants.students}/${student.remoteId}',
      data: {
        'name': student.name,
        'gradeLevel': student.gradeLevel,
        'avatarColor': student.avatarColor,
        'active': student.active,
      },
    );
    
    student.needsSync = false;
    student.lastSyncedAt = DateTime.now();
    await student.save();
  }

  Future<void> _mergeStudent(Map<String, dynamic> json) async {
    final serverId = json['id'] as String;
    final serverUpdatedAt = DateTime.parse(json['updatedAt'] as String);
    
    // Find local student by remoteId
    StudentEntity? local;
    for (final s in _db.studentsBox.values) {
      if (s.remoteId == serverId) {
        local = s;
        break;
      }
    }
    
    if (local != null) {
      // Compare timestamps - server wins if newer
      if (serverUpdatedAt.isAfter(local.updatedAt) || !local.needsSync) {
        local.name = json['name'] as String;
        local.gradeLevel = json['gradeLevel'] as String;
        local.avatarColor = json['avatarColor'] as String?;
        local.active = json['active'] as bool;
        local.familyId = json['familyId'] as String;
        local.updatedAt = serverUpdatedAt;
        local.needsSync = false;
        local.lastSyncedAt = DateTime.now();
        await local.save();
      }
    } else {
      // New from server - create locally
      final entity = StudentEntity()
        ..id = serverId // Use server ID as local ID for consistency
        ..remoteId = serverId
        ..familyId = json['familyId'] as String
        ..name = json['name'] as String
        ..gradeLevel = json['gradeLevel'] as String
        ..avatarColor = json['avatarColor'] as String?
        ..active = json['active'] as bool
        ..createdAt = DateTime.parse(json['createdAt'] as String)
        ..updatedAt = serverUpdatedAt
        ..needsSync = false
        ..lastSyncedAt = DateTime.now();
      
      await _db.studentsBox.put(entity.id, entity);
    }
  }

  // === Subject sync helpers ===

  Future<void> _createSubjectOnServer(SubjectEntity subject) async {
    final response = await _apiClient.post(
      ApiConstants.subjects,
      data: {
        'name': subject.name,
        'type': subject.type,
        'targetHours': subject.targetHours,
        'color': subject.color,
      },
    );
    
    final serverId = response.data['id'] as String;
    subject.remoteId = serverId;
    subject.familyId = response.data['familyId'] as String;
    subject.needsSync = false;
    subject.lastSyncedAt = DateTime.now();
    await subject.save();
  }

  Future<void> _updateSubjectOnServer(SubjectEntity subject) async {
    await _apiClient.patch(
      '${ApiConstants.subjects}/${subject.remoteId}',
      data: {
        'name': subject.name,
        'type': subject.type,
        'targetHours': subject.targetHours,
        'color': subject.color,
        'sortOrder': subject.sortOrder,
      },
    );
    
    subject.needsSync = false;
    subject.lastSyncedAt = DateTime.now();
    await subject.save();
  }

  Future<void> _mergeSubject(Map<String, dynamic> json) async {
    final serverId = json['id'] as String;
    final serverUpdatedAt = DateTime.parse(json['updatedAt'] as String);
    
    // Find local subject by remoteId
    SubjectEntity? local;
    for (final s in _db.subjectsBox.values) {
      if (s.remoteId == serverId) {
        local = s;
        break;
      }
    }
    
    if (local != null) {
      // Server wins if newer or local doesn't need sync
      if (serverUpdatedAt.isAfter(local.updatedAt) || !local.needsSync) {
        local.name = json['name'] as String;
        local.type = json['type'] as String;
        local.targetHours = (json['targetHours'] as num?)?.toDouble();
        local.color = json['color'] as String;
        local.sortOrder = json['sortOrder'] as int? ?? 0;
        local.active = json['active'] as bool;
        local.familyId = json['familyId'] as String;
        local.updatedAt = serverUpdatedAt;
        local.needsSync = false;
        local.lastSyncedAt = DateTime.now();
        await local.save();
      }
    } else {
      // New from server
      final entity = SubjectEntity()
        ..id = serverId
        ..remoteId = serverId
        ..familyId = json['familyId'] as String
        ..name = json['name'] as String
        ..type = json['type'] as String
        ..targetHours = (json['targetHours'] as num?)?.toDouble()
        ..color = json['color'] as String
        ..isDefault = json['isDefault'] as bool? ?? false
        ..sortOrder = json['sortOrder'] as int? ?? 0
        ..active = json['active'] as bool
        ..createdAt = DateTime.parse(json['createdAt'] as String)
        ..updatedAt = serverUpdatedAt
        ..needsSync = false
        ..lastSyncedAt = DateTime.now();
      
      await _db.subjectsBox.put(entity.id, entity);
    }
  }

  // === Log entry sync helpers ===

  Future<void> _createLogOnServer(LogEntryEntity log) async {
    // Need to map local student/subject IDs to remote IDs
    final studentRemoteId = _getRemoteStudentId(log.studentId);
    final subjectRemoteId = _getRemoteSubjectId(log.subjectId);
    
    debugPrint('[Sync] Creating log ${log.id}:');
    debugPrint('  studentId: ${log.studentId} -> remoteId: $studentRemoteId');
    debugPrint('  subjectId: ${log.subjectId} -> remoteId: $subjectRemoteId');
    
    if (studentRemoteId == null || subjectRemoteId == null) {
      debugPrint('Cannot sync log: missing remote student or subject ID');
      return;
    }
    
    final response = await _apiClient.post(
      ApiConstants.logs,
      data: {
        'studentId': studentRemoteId,
        'subjectId': subjectRemoteId,
        'date': log.date.toIso8601String().split('T')[0], // YYYY-MM-DD
        'hours': log.hours,
        'description': log.description,
        'locationType': log.locationType,
        'locationName': log.locationName,
      },
    );
    
    final serverId = response.data['id'] as String;
    log.remoteId = serverId;
    log.familyId = response.data['familyId'] as String;
    log.needsSync = false;
    log.lastSyncedAt = DateTime.now();
    await log.save();
  }

  Future<void> _updateLogOnServer(LogEntryEntity log) async {
    final subjectRemoteId = _getRemoteSubjectId(log.subjectId);
    
    await _apiClient.patch(
      '${ApiConstants.logs}/${log.remoteId}',
      data: {
        if (subjectRemoteId != null) 'subjectId': subjectRemoteId,
        'date': log.date.toIso8601String().split('T')[0],
        'hours': log.hours,
        'description': log.description,
        'locationType': log.locationType,
        'locationName': log.locationName,
      },
    );
    
    log.needsSync = false;
    log.lastSyncedAt = DateTime.now();
    await log.save();
  }

  Future<void> _mergeLog(Map<String, dynamic> json) async {
    final serverId = json['id'] as String;
    final serverUpdatedAt = DateTime.parse(json['updatedAt'] as String);
    
    // Find local log by remoteId
    LogEntryEntity? local;
    for (final l in _db.logEntriesBox.values) {
      if (l.remoteId == serverId) {
        local = l;
        break;
      }
    }
    
    // Map server student/subject IDs to local IDs
    final serverStudentId = json['studentId'] as String;
    final serverSubjectId = json['subjectId'] as String;
    final localStudentId = _getLocalStudentId(serverStudentId) ?? serverStudentId;
    final localSubjectId = _getLocalSubjectId(serverSubjectId) ?? serverSubjectId;
    
    if (local != null) {
      // Server wins if newer
      if (serverUpdatedAt.isAfter(local.updatedAt) || !local.needsSync) {
        local.studentId = localStudentId;
        local.subjectId = localSubjectId;
        local.date = DateTime.parse(json['date'] as String);
        local.hours = (json['hours'] as num).toDouble();
        local.description = json['description'] as String? ?? '';
        local.locationType = json['locationType'] as String? ?? 'home';
        local.locationName = json['locationName'] as String?;
        local.status = json['status'] as String? ?? 'approved';
        local.schoolYear = json['schoolYear'] as String;
        local.familyId = json['familyId'] as String;
        local.updatedAt = serverUpdatedAt;
        local.needsSync = false;
        local.lastSyncedAt = DateTime.now();
        await local.save();
      }
    } else {
      // New from server
      final entity = LogEntryEntity()
        ..id = serverId
        ..remoteId = serverId
        ..familyId = json['familyId'] as String
        ..organizationId = json['organizationId'] as String?
        ..studentId = localStudentId
        ..subjectId = localSubjectId
        ..date = DateTime.parse(json['date'] as String)
        ..hours = (json['hours'] as num).toDouble()
        ..description = json['description'] as String? ?? ''
        ..locationType = json['locationType'] as String? ?? 'home'
        ..locationId = json['locationId'] as String?
        ..locationName = json['locationName'] as String?
        ..submittedBy = json['submittedBy'] as String? ?? 'server'
        ..status = json['status'] as String? ?? 'approved'
        ..schoolYear = json['schoolYear'] as String
        ..createdAt = DateTime.parse(json['createdAt'] as String)
        ..updatedAt = serverUpdatedAt
        ..needsSync = false
        ..lastSyncedAt = DateTime.now();
      
      await _db.logEntriesBox.put(entity.id, entity);
    }
  }

  // === ID mapping helpers ===

  String? _getRemoteStudentId(String localId) {
    final student = _db.studentsBox.get(localId);
    return student?.remoteId ?? (student?.id == student?.remoteId ? localId : null);
  }

  String? _getRemoteSubjectId(String localId) {
    final subject = _db.subjectsBox.get(localId);
    return subject?.remoteId ?? (subject?.id == subject?.remoteId ? localId : null);
  }

  String? _getLocalStudentId(String remoteId) {
    for (final s in _db.studentsBox.values) {
      if (s.remoteId == remoteId) return s.id;
    }
    return null;
  }

  String? _getLocalSubjectId(String remoteId) {
    for (final s in _db.subjectsBox.values) {
      if (s.remoteId == remoteId) return s.id;
    }
    return null;
  }

  // === Sync metadata ===

  Future<void> _updateSyncMeta() async {
    final meta = _db.syncMetaBox.get('sync_meta') ?? SyncMetaEntity.createDefault();
    meta.lastFullSync = DateTime.now();
    meta.pendingChangesCount = _countPendingChanges();
    await _db.syncMetaBox.put('sync_meta', meta);
  }

  int _countPendingChanges() {
    int count = 0;
    count += _db.studentsBox.values.where((s) => s.needsSync).length;
    count += _db.subjectsBox.values.where((s) => s.needsSync).length;
    count += _db.logEntriesBox.values.where((l) => l.needsSync).length;
    return count;
  }

  /// Get the last sync time
  DateTime? getLastSyncTime() {
    return _db.syncMetaBox.get('sync_meta')?.lastFullSync;
  }

  /// Get count of pending changes
  int getPendingChangesCount() {
    return _countPendingChanges();
  }

  /// Check if there are pending changes to sync
  bool hasPendingChanges() {
    return _countPendingChanges() > 0;
  }
}

/// Internal helper for counting push/pull results
class _PushPullCounts {
  final int students;
  final int subjects;
  final int logs;

  _PushPullCounts({
    this.students = 0,
    this.subjects = 0,
    this.logs = 0,
  });
}
