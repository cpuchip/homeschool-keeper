import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/logs_service.dart';
import '../models/log_entry.dart';

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

  /// Get total hours
  double get totalHours =>
      logs.fold(0, (sum, log) => sum + log.hours);
}

/// Notifier for managing logs state
class LogsNotifier extends StateNotifier<LogsState> {
  final LogsService _service;

  LogsNotifier(this._service) : super(const LogsState());

  /// Load logs from API with optional filters
  Future<void> loadLogs({
    String? studentId,
    String? subjectId,
    String? schoolYear,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      filterStudentId: studentId,
      filterSubjectId: subjectId,
      clearStudentFilter: studentId == null,
      clearSubjectFilter: subjectId == null,
    );

    try {
      final logs = await _service.getAll(
        studentId: studentId,
        subjectId: subjectId,
        schoolYear: schoolYear,
      );
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
  }) async {
    try {
      final log = await _service.create(
        studentId: studentId,
        subjectId: subjectId,
        date: date,
        hours: hours,
        description: description,
        locationType: locationType,
        locationName: locationName,
      );
      state = state.copyWith(
        logs: [...state.logs, log],
      );
      return log;
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
      final updated = await _service.update(
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
      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Delete a log entry
  Future<bool> deleteLog(String id) async {
    try {
      await _service.delete(id);
      state = state.copyWith(
        logs: state.logs.where((l) => l.id != id).toList(),
      );
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

/// Provider for logs state
final logsProvider =
    StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  final service = ref.watch(logsServiceProvider);
  return LogsNotifier(service);
},);
