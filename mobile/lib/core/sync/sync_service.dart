import '../api/api_client.dart';
import '../constants.dart';
import '../database/database_service.dart';
import '../database/hive_entities.dart';
import '../utils/logger.dart';
import 'conflict_item.dart';

export 'conflict_item.dart';

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
  final List<ConflictItem> conflictItems;
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
    this.conflictItems = const [],
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
    List<ConflictItem> conflictItems = const [],
  }) {
    return SyncResult(
      success: true,
      pushedStudents: pushedStudents,
      pushedSubjects: pushedSubjects,
      pushedLogs: pushedLogs,
      pulledStudents: pulledStudents,
      pulledSubjects: pulledSubjects,
      pulledLogs: pulledLogs,
      conflictItems: conflictItems,
    );
  }

  int get totalPushed => pushedStudents + pushedSubjects + pushedLogs;
  int get totalPulled => pulledStudents + pulledSubjects + pulledLogs;
  int get conflicts => conflictItems.length;
  bool get hasConflicts => conflictItems.isNotEmpty;
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
  /// Set [incremental] to true to only pull changes since last sync
  Future<SyncResult> performFullSync({bool incremental = true}) async {
    if (_status == SyncStatus.syncing) {
      Log.sync.d('Already syncing, skipping');
      return SyncResult.error('Sync already in progress');
    }

    Log.sync.d('Starting ${incremental ? 'incremental' : 'full'} sync...');
    _status = SyncStatus.syncing;
    _lastError = null;

    try {
      // Push local changes first
      Log.sync.d('Pushing local changes...');
      final pushResult = await _pushLocalChanges();
      Log.sync.d(
        'Pushed: ${pushResult.students} students, ${pushResult.subjects} subjects, ${pushResult.logs} logs',
      );

      // Then pull server data (use last sync time for incremental sync)
      final since = incremental ? getLastSyncTime() : null;
      Log.sync
          .d('Pulling server data${since != null ? ' since $since' : ''}...');
      final pullResult = await _pullServerData(since: since);
      Log.sync.d(
        'Pulled: ${pullResult.students} students, ${pullResult.subjects} subjects, ${pullResult.logs} logs',
      );
      if (pullResult.conflictItems.isNotEmpty) {
        Log.sync.w('${pullResult.conflictItems.length} conflicts detected');
      }

      // Update sync metadata
      await _updateSyncMeta();

      _status = SyncStatus.success;
      Log.sync.d(
        '${incremental ? 'Incremental' : 'Full'} sync completed successfully!',
      );

      return SyncResult.success(
        pushedStudents: pushResult.students,
        pushedSubjects: pushResult.subjects,
        pushedLogs: pushResult.logs,
        pulledStudents: pullResult.students,
        pulledSubjects: pullResult.subjects,
        pulledLogs: pullResult.logs,
        conflictItems: pullResult.conflictItems,
      );
    } catch (e, stack) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      Log.sync.e('Sync error', e, stack);
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
    final pendingStudents =
        _db.studentsBox.values.where((s) => s.needsSync).toList();

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
        Log.sync.w('Failed to sync student ${student.id}: $e');
        // Continue with other items, don't fail entire sync
      }
    }

    // Push subjects (including defaults - they need remoteIds for log sync)
    final pendingSubjects =
        _db.subjectsBox.values.where((s) => s.needsSync).toList();

    for (final subject in pendingSubjects) {
      try {
        if (subject.remoteId != null) {
          await _updateSubjectOnServer(subject);
        } else {
          await _createSubjectOnServer(subject);
        }
        subjects++;
      } catch (e) {
        Log.sync.w('Failed to sync subject ${subject.id}: $e');
      }
    }

    // Push log entries
    final pendingLogs =
        _db.logEntriesBox.values.where((l) => l.needsSync).toList();

    for (final log in pendingLogs) {
      try {
        if (log.remoteId != null) {
          await _updateLogOnServer(log);
        } else {
          await _createLogOnServer(log);
        }
        logs++;
      } catch (e) {
        Log.sync.w('Failed to sync log ${log.id}: $e');
      }
    }

    return _PushPullCounts(students: students, subjects: subjects, logs: logs);
  }

  /// Pull server data and merge with local
  /// Pull server data and merge with local
  /// [since] - if provided, only pulls records updated after this time (incremental sync)
  Future<_PushPullCounts> _pullServerData({DateTime? since}) async {
    int students = 0;
    int subjects = 0;
    int logs = 0;
    final List<ConflictItem> conflictItems = [];

    // Build query params for incremental sync
    final queryParams = since != null
        ? {'since': since.toUtc().toIso8601String()}
        : <String, String>{};

    // Pull students
    try {
      final response = await _apiClient.get(
        ApiConstants.students,
        queryParameters: queryParams,
      );
      final serverStudents = (response.data as List<dynamic>?) ?? [];

      for (final json in serverStudents) {
        final conflict = await _mergeStudent(json as Map<String, dynamic>);
        if (conflict != null) conflictItems.add(conflict);
        students++;
      }
    } catch (e) {
      Log.sync.e('Failed to pull students', e);
      rethrow;
    }

    // Pull subjects
    try {
      final response = await _apiClient.get(
        ApiConstants.subjects,
        queryParameters: queryParams,
      );
      final serverSubjects = (response.data as List<dynamic>?) ?? [];

      for (final json in serverSubjects) {
        final conflict = await _mergeSubject(json as Map<String, dynamic>);
        if (conflict != null) conflictItems.add(conflict);
        subjects++;
      }
    } catch (e) {
      Log.sync.e('Failed to pull subjects', e);
      rethrow;
    }

    // Pull logs
    try {
      final response = await _apiClient.get(
        ApiConstants.logs,
        queryParameters: queryParams,
      );
      // Logs endpoint returns {logs: [...], total: N, page: N, limit: N}
      final data = response.data as Map<String, dynamic>?;
      final serverLogs = (data?['logs'] as List<dynamic>?) ?? [];

      for (final json in serverLogs) {
        final conflict = await _mergeLog(json as Map<String, dynamic>);
        if (conflict != null) conflictItems.add(conflict);
        logs++;
      }
    } catch (e) {
      Log.sync.e('Failed to pull logs', e);
      rethrow;
    }

    return _PushPullCounts(
      students: students,
      subjects: subjects,
      logs: logs,
      conflictItems: conflictItems,
    );
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

  /// Merge student from server. Returns ConflictItem if conflict detected (local has unsaved changes and server is newer).
  Future<ConflictItem?> _mergeStudent(Map<String, dynamic> json) async {
    final serverId = json['id'] as String;
    final serverUpdatedAt = DateTime.parse(json['updatedAt'] as String);
    ConflictItem? conflict;

    // Find local student by remoteId
    StudentEntity? local;
    for (final s in _db.studentsBox.values) {
      if (s.remoteId == serverId) {
        local = s;
        break;
      }
    }

    if (local != null) {
      // Conflict: local has unsaved changes AND server is newer
      if (local.needsSync && serverUpdatedAt.isAfter(local.updatedAt)) {
        Log.sync.w('Conflict detected for student ${local.name}');
        conflict = ConflictItem(
          entityType: ConflictEntityType.student,
          entityId: local.id,
          remoteId: serverId,
          displayName: local.name,
          localUpdatedAt: local.updatedAt,
          serverUpdatedAt: serverUpdatedAt,
          localData: {
            'name': local.name,
            'gradeLevel': local.gradeLevel,
            'avatarColor': local.avatarColor,
            'active': local.active,
          },
          serverData: {
            'name': json['name'],
            'gradeLevel': json['gradeLevel'],
            'avatarColor': json['avatarColor'],
            'active': json['active'],
          },
          fieldDiffs: createStudentFieldDiffs(
            localName: local.name,
            serverName: json['name'] as String,
            localGradeLevel: local.gradeLevel,
            serverGradeLevel: json['gradeLevel'] as String,
            localAvatarColor: local.avatarColor,
            serverAvatarColor: json['avatarColor'] as String?,
            localActive: local.active,
            serverActive: json['active'] as bool,
          ),
        );
        // NOTE: We now defer the merge decision to the UI.
        // For now, we still server-wins but track the conflict.
      }
      // Compare timestamps - server wins if newer OR no local changes
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
    return conflict;
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

  /// Merge subject from server. Returns ConflictItem if conflict detected (local has unsaved changes and server is newer).
  Future<ConflictItem?> _mergeSubject(Map<String, dynamic> json) async {
    final serverId = json['id'] as String;
    final serverUpdatedAt = DateTime.parse(json['updatedAt'] as String);
    ConflictItem? conflict;

    // Find local subject by remoteId
    SubjectEntity? local;
    for (final s in _db.subjectsBox.values) {
      if (s.remoteId == serverId) {
        local = s;
        break;
      }
    }

    if (local != null) {
      // Conflict: local has unsaved changes AND server is newer
      if (local.needsSync && serverUpdatedAt.isAfter(local.updatedAt)) {
        Log.sync.w('Conflict detected for subject ${local.name}');
        conflict = ConflictItem(
          entityType: ConflictEntityType.subject,
          entityId: local.id,
          remoteId: serverId,
          displayName: local.name,
          localUpdatedAt: local.updatedAt,
          serverUpdatedAt: serverUpdatedAt,
          localData: {
            'name': local.name,
            'type': local.type,
            'targetHours': local.targetHours,
            'color': local.color,
            'sortOrder': local.sortOrder,
            'active': local.active,
          },
          serverData: {
            'name': json['name'],
            'type': json['type'],
            'targetHours': json['targetHours'],
            'color': json['color'],
            'sortOrder': json['sortOrder'],
            'active': json['active'],
          },
          fieldDiffs: createSubjectFieldDiffs(
            localName: local.name,
            serverName: json['name'] as String,
            localType: local.type,
            serverType: json['type'] as String,
            localTargetHours: local.targetHours,
            serverTargetHours: (json['targetHours'] as num?)?.toDouble(),
            localColor: local.color,
            serverColor: json['color'] as String,
            localSortOrder: local.sortOrder,
            serverSortOrder: json['sortOrder'] as int? ?? 0,
            localActive: local.active,
            serverActive: json['active'] as bool,
          ),
        );
      }
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
    return conflict;
  }

  // === Log entry sync helpers ===

  Future<void> _createLogOnServer(LogEntryEntity log) async {
    // Need to map local student/subject IDs to remote IDs
    final studentRemoteId = _getRemoteStudentId(log.studentId);
    final subjectRemoteId = _getRemoteSubjectId(log.subjectId);

    Log.sync.d(
      'Creating log ${log.id}: studentId=${log.studentId}->$studentRemoteId, subjectId=${log.subjectId}->$subjectRemoteId',
    );

    if (studentRemoteId == null || subjectRemoteId == null) {
      Log.sync.w('Cannot sync log: missing remote student or subject ID');
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

  /// Merge log from server. Returns ConflictItem if conflict detected (local has unsaved changes and server is newer).
  Future<ConflictItem?> _mergeLog(Map<String, dynamic> json) async {
    final serverId = json['id'] as String;
    final serverUpdatedAt = DateTime.parse(json['updatedAt'] as String);
    ConflictItem? conflict;

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
    final localStudentId =
        _getLocalStudentId(serverStudentId) ?? serverStudentId;
    final localSubjectId =
        _getLocalSubjectId(serverSubjectId) ?? serverSubjectId;

    if (local != null) {
      // Conflict: local has unsaved changes AND server is newer
      if (local.needsSync && serverUpdatedAt.isAfter(local.updatedAt)) {
        Log.sync.w('Conflict detected for log ${local.id}');

        // Get student/subject names for display
        final localStudent = _db.studentsBox.get(local.studentId);
        final localSubject = _db.subjectsBox.get(local.subjectId);
        final serverStudent = _db.studentsBox.values.firstWhere(
          (s) => s.remoteId == serverStudentId,
          orElse: () => localStudent ?? StudentEntity()
            ..name = 'Unknown',
        );
        final serverSubject = _db.subjectsBox.values.firstWhere(
          (s) => s.remoteId == serverSubjectId,
          orElse: () => localSubject ?? SubjectEntity()
            ..name = 'Unknown',
        );

        conflict = ConflictItem(
          entityType: ConflictEntityType.log,
          entityId: local.id,
          remoteId: serverId,
          displayName:
              '${localStudent?.name ?? "Unknown"} - ${localSubject?.name ?? "Unknown"} (${_formatDate(local.date)})',
          localUpdatedAt: local.updatedAt,
          serverUpdatedAt: serverUpdatedAt,
          localData: {
            'studentId': local.studentId,
            'subjectId': local.subjectId,
            'date': local.date.toIso8601String(),
            'hours': local.hours,
            'description': local.description,
            'locationType': local.locationType,
            'locationName': local.locationName,
          },
          serverData: {
            'studentId': serverStudentId,
            'subjectId': serverSubjectId,
            'date': json['date'],
            'hours': json['hours'],
            'description': json['description'],
            'locationType': json['locationType'],
            'locationName': json['locationName'],
          },
          fieldDiffs: createLogFieldDiffs(
            localStudentName: localStudent?.name ?? 'Unknown',
            serverStudentName: serverStudent.name,
            localSubjectName: localSubject?.name ?? 'Unknown',
            serverSubjectName: serverSubject.name,
            localDate: local.date,
            serverDate: DateTime.parse(json['date'] as String),
            localHours: local.hours,
            serverHours: (json['hours'] as num).toDouble(),
            localDescription: local.description,
            serverDescription: json['description'] as String? ?? '',
            localLocationType: local.locationType,
            serverLocationType: json['locationType'] as String? ?? 'home',
            localLocationName: local.locationName,
            serverLocationName: json['locationName'] as String?,
          ),
        );
      }
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
    return conflict;
  }

  /// Helper to format date for display
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // === ID mapping helpers ===

  String? _getRemoteStudentId(String localId) {
    final student = _db.studentsBox.get(localId);
    return student?.remoteId ??
        (student?.id == student?.remoteId ? localId : null);
  }

  String? _getRemoteSubjectId(String localId) {
    final subject = _db.subjectsBox.get(localId);
    return subject?.remoteId ??
        (subject?.id == subject?.remoteId ? localId : null);
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
    final meta =
        _db.syncMetaBox.get('sync_meta') ?? SyncMetaEntity.createDefault();
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

  /// Apply conflict resolutions chosen by the user
  /// Returns the number of conflicts resolved
  Future<int> applyConflictResolutions(
      List<ResolvedConflict> resolutions,
  ) async {
    int resolvedCount = 0;

    for (final resolution in resolutions) {
      final conflict = resolution.conflict;

      switch (resolution.resolution) {
        case ConflictResolution.keepLocal:
          // Mark local version for re-sync to overwrite server
          await _markForResync(conflict);
          resolvedCount++;
          break;

        case ConflictResolution.keepServer:
          // Server version already applied during merge, nothing to do
          resolvedCount++;
          break;

        case ConflictResolution.keepBoth:
          // For now, treat same as keepLocal (future: could create duplicate)
          await _markForResync(conflict);
          resolvedCount++;
          break;

        case ConflictResolution.skip:
          // Do nothing, leave as-is
          break;
      }
    }

    // If any conflicts were resolved with keepLocal, push changes
    final hasLocalChanges = resolutions.any(
      (r) =>
          r.resolution == ConflictResolution.keepLocal ||
          r.resolution == ConflictResolution.keepBoth,
    );

    if (hasLocalChanges) {
      await pushChanges();
    }

    return resolvedCount;
  }

  /// Mark an entity for re-sync by restoring local data and setting needsSync
  Future<void> _markForResync(ConflictItem conflict) async {
    switch (conflict.entityType) {
      case ConflictEntityType.student:
        final student = _db.studentsBox.get(conflict.entityId);
        if (student != null) {
          // Restore local data from conflict
          student.name = conflict.localData['name'] as String;
          student.gradeLevel = conflict.localData['gradeLevel'] as String;
          student.avatarColor = conflict.localData['avatarColor'] as String?;
          student.active = conflict.localData['active'] as bool;
          student.updatedAt = DateTime.now();
          student.needsSync = true;
          await student.save();
        }
        break;

      case ConflictEntityType.subject:
        final subject = _db.subjectsBox.get(conflict.entityId);
        if (subject != null) {
          subject.name = conflict.localData['name'] as String;
          subject.type = conflict.localData['type'] as String;
          subject.targetHours =
              (conflict.localData['targetHours'] as num?)?.toDouble();
          subject.color = conflict.localData['color'] as String;
          subject.sortOrder = conflict.localData['sortOrder'] as int? ?? 0;
          subject.active = conflict.localData['active'] as bool;
          subject.updatedAt = DateTime.now();
          subject.needsSync = true;
          await subject.save();
        }
        break;

      case ConflictEntityType.log:
        final log = _db.logEntriesBox.get(conflict.entityId);
        if (log != null) {
          log.studentId = conflict.localData['studentId'] as String;
          log.subjectId = conflict.localData['subjectId'] as String;
          log.date = DateTime.parse(conflict.localData['date'] as String);
          log.hours = (conflict.localData['hours'] as num).toDouble();
          log.description = conflict.localData['description'] as String? ?? '';
          log.locationType =
              conflict.localData['locationType'] as String? ?? 'home';
          log.locationName = conflict.localData['locationName'] as String?;
          log.updatedAt = DateTime.now();
          log.needsSync = true;
          await log.save();
        }
        break;
    }
  }
}

/// Internal helper for counting push/pull results
class _PushPullCounts {
  final int students;
  final int subjects;
  final int logs;
  final List<ConflictItem> conflictItems;

  _PushPullCounts({
    this.students = 0,
    this.subjects = 0,
    this.logs = 0,
    this.conflictItems = const [],
  });
}
