import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/stats_service.dart';
import '../models/stats.dart';

/// State for family stats with loading and error states
class StatsState {
  final FamilyStats? familyStats;
  final bool isLoading;
  final String? error;

  const StatsState({
    this.familyStats,
    this.isLoading = false,
    this.error,
  });

  StatsState copyWith({
    FamilyStats? familyStats,
    bool? isLoading,
    String? error,
    bool clearStats = false,
  }) {
    return StatsState(
      familyStats: clearStats ? null : (familyStats ?? this.familyStats),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get total hours across all students
  double get totalHours => familyStats?.totalHours ?? 0;

  /// Get total log count
  int get totalLogCount => familyStats?.totalLogCount ?? 0;

  /// Get number of students
  int get studentCount => familyStats?.students.length ?? 0;
}

/// Notifier for managing stats state (local-first)
class StatsNotifier extends StateNotifier<StatsState> {
  final LocalStatsService _service;

  StatsNotifier(this._service) : super(const StatsState()) {
    // Load stats from local storage immediately
    _loadFromLocal();
  }

  /// Load stats from local Hive storage
  void _loadFromLocal({String? schoolYear}) {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = _service.getFamilyStats(schoolYear: schoolYear);
      state = state.copyWith(familyStats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load family stats
  Future<void> loadFamilyStats({String? schoolYear}) async {
    _loadFromLocal(schoolYear: schoolYear);
  }

  /// Get stats for a specific student
  StudentStats? getStudentStats(String studentId, {String? schoolYear}) {
    try {
      return _service.getStudentStats(studentId, schoolYear: schoolYear);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear stats (e.g., on logout)
  void clearStats() {
    state = state.copyWith(clearStats: true);
  }

  /// Refresh stats
  void refresh() {
    _loadFromLocal();
  }
}

/// Provider for local stats service
final localStatsServiceProvider = Provider<LocalStatsService>((ref) {
  return LocalStatsService();
});

/// Provider for stats state
final statsProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  final service = ref.watch(localStatsServiceProvider);
  return StatsNotifier(service);
});

