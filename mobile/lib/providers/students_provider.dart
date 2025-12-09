import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/students_service.dart';
import '../models/student.dart';

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

/// Notifier for managing students state
class StudentsNotifier extends StateNotifier<StudentsState> {
  final StudentsService _service;

  StudentsNotifier(this._service) : super(const StudentsState()) {
    // Don't auto-load - let the UI trigger it
  }

  /// Load all students from API
  Future<void> loadStudents() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final students = await _service.getAll();
      state = state.copyWith(students: students, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new student
  Future<Student?> createStudent({
    required String name,
    required String gradeLevel,
    String? avatarColor,
  }) async {
    try {
      final student = await _service.create(
        name: name,
        gradeLevel: gradeLevel,
        avatarColor: avatarColor,
      );
      state = state.copyWith(
        students: [...state.students, student],
      );
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
      final updated = await _service.update(
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
      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Delete a student
  Future<bool> deleteStudent(String id) async {
    try {
      await _service.delete(id);
      state = state.copyWith(
        students: state.students.where((s) => s.id != id).toList(),
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

/// Provider for students state
final studentsProvider =
    StateNotifierProvider<StudentsNotifier, StudentsState>((ref) {
  final service = ref.watch(studentsServiceProvider);
  return StudentsNotifier(service);
},);
