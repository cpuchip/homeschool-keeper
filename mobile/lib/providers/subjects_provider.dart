import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/subject_repository.dart';
import '../models/subject.dart';

/// State for subjects list with loading and error states
class SubjectsState {
  final List<Subject> subjects;
  final bool isLoading;
  final String? error;

  const SubjectsState({
    this.subjects = const [],
    this.isLoading = false,
    this.error,
  });

  SubjectsState copyWith({
    List<Subject>? subjects,
    bool? isLoading,
    String? error,
  }) {
    return SubjectsState(
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get only active subjects
  List<Subject> get activeSubjects =>
      subjects.where((s) => s.active).toList();

  /// Get core subjects
  List<Subject> get coreSubjects =>
      activeSubjects.where((s) => s.type == SubjectType.core).toList();

  /// Get elective subjects
  List<Subject> get electiveSubjects =>
      activeSubjects.where((s) => s.type == SubjectType.elective).toList();
}

/// Notifier for managing subjects state (local-first)
class SubjectsNotifier extends StateNotifier<SubjectsState> {
  final SubjectRepository _repository;

  SubjectsNotifier(this._repository) : super(const SubjectsState()) {
    // Load from local storage immediately
    _loadFromLocal();
  }

  /// Load subjects from local Hive storage
  void _loadFromLocal() {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final subjects = _repository.getAll();
      state = state.copyWith(subjects: subjects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reload subjects from local storage
  Future<void> loadSubjects() async {
    _loadFromLocal();
  }

  /// Create a new subject
  Future<Subject?> createSubject({
    required String name,
    required String type,
    required String color,
    double? targetHours,
  }) async {
    try {
      final subject = await _repository.create(
        name: name,
        type: type,
        color: color,
        targetHours: targetHours,
      );
      state = state.copyWith(
        subjects: [...state.subjects, subject],
      );
      return subject;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update an existing subject
  Future<Subject?> updateSubject(
    String id, {
    String? name,
    String? type,
    String? color,
    double? targetHours,
    int? sortOrder,
    bool? active,
  }) async {
    try {
      final updated = await _repository.update(
        id,
        name: name,
        type: type,
        color: color,
        targetHours: targetHours,
        sortOrder: sortOrder,
        active: active,
      );
      state = state.copyWith(
        subjects: state.subjects
            .map((s) => s.id == id ? updated : s)
            .toList(),
      );
      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Delete a subject
  Future<bool> deleteSubject(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        subjects: state.subjects.where((s) => s.id != id).toList(),
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

/// Provider for local subject repository
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository();
});

/// Provider for subjects state
final subjectsProvider =
    StateNotifierProvider<SubjectsNotifier, SubjectsState>((ref) {
  final repository = ref.watch(subjectRepositoryProvider);
  return SubjectsNotifier(repository);
});
