import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/student_repository.dart';
import '../models/student.dart';
import '../core/sync/auto_sync_service.dart';

/// State for students list with loading and error states
class StudentsState {
  final List<Student> students;
  final bool isLoading;
  final String? error;

  const StudentsState({
    this.students = const [],
    this.isLoading = false,
    this.error,
  });

  StudentsState copyWith({
    List<Student>? students,
    bool? isLoading,
    String? error,
  }) {
    return StudentsState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get only active students
  List<Student> get activeStudents =>
      students.where((s) => s.active).toList();
}

/// Notifier for managing students state (local-first)
class StudentsNotifier extends StateNotifier<StudentsState> {
  final StudentRepository _repository;

  StudentsNotifier(this._repository) : super(const StudentsState()) {
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

  /// Load students from local Hive storage
  void _loadFromLocal() {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final students = _repository.getAll();
      state = state.copyWith(students: students, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reload students from local storage
  Future<void> loadStudents() async {
    _loadFromLocal();
  }

  /// Create a new student
  Future<Student?> createStudent({
    required String name,
    required String gradeLevel,
    String? avatarColor,
  }) async {
    try {
      final student = await _repository.create(
        name: name,
        gradeLevel: gradeLevel,
        avatarColor: avatarColor,
      );
      state = state.copyWith(
        students: [...state.students, student],
      );
      
      // Trigger auto-sync
      _notifyAutoSync();
      
      return student;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update an existing student
  Future<Student?> updateStudent(
    String id, {
    String? name,
    String? gradeLevel,
    String? avatarColor,
    bool? active,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        name: name,
        gradeLevel: gradeLevel,
        avatarColor: avatarColor,
        active: active,
      );
      state = state.copyWith(
        students: state.students
            .map((s) => s.id == id ? updated : s)
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

  /// Delete a student
  Future<bool> deleteStudent(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        students: state.students.where((s) => s.id != id).toList(),
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

/// Provider for local student repository
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

/// Provider for students state
final studentsProvider =
    StateNotifierProvider<StudentsNotifier, StudentsState>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return StudentsNotifier(repository);
});
