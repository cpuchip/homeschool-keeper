import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../repositories/log_entry_repository.dart';
import '../models/log_entry.dart';
import '../core/sync/auto_sync_service.dart';

/// State for logs list with loading and error states
class LogsState {
  final List<LogEntry> logs;
  final bool isLoading;
  final String? error;
  final String? filterStudentId;
  final String? filterSubjectId;

  const LogsState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.filterStudentId,
    this.filterSubjectId,
  });

  LogsState copyWith({
    List<LogEntry>? logs,
    bool? isLoading,
    String? error,
    String? filterStudentId,
    String? filterSubjectId,
    bool clearStudentFilter = false,
    bool clearSubjectFilter = false,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterStudentId:
          clearStudentFilter ? null : (filterStudentId ?? this.filterStudentId),
      filterSubjectId:
          clearSubjectFilter ? null : (filterSubjectId ?? this.filterSubjectId),
    );
  }

  /// Get logs sorted by date (newest first)
  List<LogEntry> get sortedByDate {
    final sorted = List<LogEntry>.from(logs);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Get logs grouped by groupId for display
  /// Returns a list of LogGroup (either single log or group of logs with same groupId)
  List<LogGroup> get groupedLogs {
    final sorted = sortedByDate;
    final groups = <String, List<LogEntry>>{};
    final singles = <LogEntry>[];

    for (final log in sorted) {
      if (log.groupId != null && log.groupId!.isNotEmpty) {
        groups.putIfAbsent(log.groupId!, () => []).add(log);
      } else {
        singles.add(log);
      }
    }

    // Build result: convert groups and singles to LogGroup objects
    final result = <LogGroup>[];
    final processedGroupIds = <String>{};

    for (final log in sorted) {
      if (log.groupId != null && log.groupId!.isNotEmpty) {
        if (!processedGroupIds.contains(log.groupId)) {
          processedGroupIds.add(log.groupId!);
          result.add(
            LogGroup(
              logs: groups[log.groupId]!,
              isGroup: true,
            ),
          );
        }
      } else {
        result.add(
          LogGroup(
            logs: [log],
            isGroup: false,
          ),
        );
      }
    }

    return result;
  }

  /// Get total hours
  double get totalHours =>
      logs.fold(0, (sum, log) => sum + log.hours);
}

/// Represents a single log or a group of logs with the same groupId
class LogGroup {
  final List<LogEntry> logs;
  final bool isGroup;

  const LogGroup({
    required this.logs,
    required this.isGroup,
  });

  /// The first log in the group (used for display info like date, subject)
  LogEntry get primaryLog => logs.first;

  /// Total hours across all logs in the group
  double get totalHours => logs.fold(0.0, (sum, log) => sum + log.hours);

  /// All student IDs in this group
  List<String> get studentIds => logs.map((l) => l.studentId).toList();

  /// The groupId (null if single log)
  String? get groupId => isGroup ? logs.first.groupId : null;
}

/// Notifier for managing logs state (local-first)
class LogsNotifier extends StateNotifier<LogsState> {
  final LogEntryRepository _repository;

  LogsNotifier(this._repository) : super(const LogsState()) {
    // Load from local storage immediately
    _loadFromLocal();
  }

  /// Notify auto-sync service of data changes
  void _notifyAutoSync() {
    try {
      AutoSyncService.instance.notifyDataChanged();
    } catch (_) {
      // AutoSync not initialized yet, ignore
    }
  }

  /// Load logs from local Hive storage
  void _loadFromLocal({String? studentId, String? subjectId}) {
    state = state.copyWith(
      isLoading: true,
      error: null,
      filterStudentId: studentId,
      filterSubjectId: subjectId,
      clearStudentFilter: studentId == null,
      clearSubjectFilter: subjectId == null,
    );
    try {
      List<LogEntry> logs;
      if (studentId != null) {
        logs = _repository.getByStudent(studentId);
      } else if (subjectId != null) {
        logs = _repository.getBySubject(subjectId);
      } else {
        logs = _repository.getAll();
      }
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load logs with optional filters
  Future<void> loadLogs({
    String? studentId,
    String? subjectId,
    String? schoolYear,
  }) async {
    _loadFromLocal(studentId: studentId, subjectId: subjectId);
  }

  /// Create a new log entry
  Future<LogEntry?> createLog({
    required String studentId,
    required String subjectId,
    required DateTime date,
    required double hours,
    String? description,
    String locationType = 'home',
    String? locationName,
    String? groupId,
  }) async {
    try {
      final log = await _repository.create(
        studentId: studentId,
        subjectId: subjectId,
        date: date,
        hours: hours,
        description: description ?? '',
        locationType: locationType,
        locationName: locationName,
        groupId: groupId,
      );
      state = state.copyWith(
        logs: [log, ...state.logs], // Add to front (newest first)
      );
      
      // Trigger auto-sync
      _notifyAutoSync();
      
      return log;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Create log entries for multiple students (same activity)
  /// Returns the list of created logs, or null if failed
  Future<List<LogEntry>?> createMultiStudentLog({
    required List<String> studentIds,
    required String subjectId,
    required DateTime date,
    required double hours,
    String? description,
    String locationType = 'home',
    String? locationName,
  }) async {
    if (studentIds.isEmpty) return null;
    
    // Single student - no group needed
    if (studentIds.length == 1) {
      final log = await createLog(
        studentId: studentIds.first,
        subjectId: subjectId,
        date: date,
        hours: hours,
        description: description,
        locationType: locationType,
        locationName: locationName,
      );
      return log != null ? [log] : null;
    }
    
    try {
      // Generate a unique groupId for this multi-student log
      final groupId = const Uuid().v4();
      final createdLogs = <LogEntry>[];
      
      for (final studentId in studentIds) {
        final log = await _repository.create(
          studentId: studentId,
          subjectId: subjectId,
          date: date,
          hours: hours,
          description: description ?? '',
          locationType: locationType,
          locationName: locationName,
          groupId: groupId,
        );
        createdLogs.add(log);
      }
      
      // Update state with all new logs
      state = state.copyWith(
        logs: [...createdLogs, ...state.logs],
      );
      
      // Trigger auto-sync
      _notifyAutoSync();
      
      return createdLogs;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update an existing log entry
  Future<LogEntry?> updateLog(
    String id, {
    String? studentId,
    String? subjectId,
    DateTime? date,
    double? hours,
    String? description,
    String? locationType,
    String? locationName,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        studentId: studentId,
        subjectId: subjectId,
        date: date,
        hours: hours,
        description: description,
        locationType: locationType,
        locationName: locationName,
      );
      state = state.copyWith(
        logs: state.logs
            .map((l) => l.id == id ? updated : l)
            .toList(),
      );
      
      // Trigger auto-sync
      _notifyAutoSync();
      
      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Delete a log entry
  Future<bool> deleteLog(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        logs: state.logs.where((l) => l.id != id).toList(),
      );
      
      // Trigger auto-sync
      _notifyAutoSync();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for local log entry repository
final logEntryRepositoryProvider = Provider<LogEntryRepository>((ref) {
  return LogEntryRepository();
});

/// Provider for logs state
final logsProvider =
    StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  final repository = ref.watch(logEntryRepositoryProvider);
  return LogsNotifier(repository);
});

