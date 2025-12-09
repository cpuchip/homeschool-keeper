import '../core/database/database_service.dart';
import '../core/database/hive_entities.dart';
import '../models/student.dart';

/// Local repository for Student data using Hive
class StudentRepository {
  final DatabaseService _db;

  StudentRepository({DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  /// Get all active students
  List<Student> getAll() {
    return _db.studentsBox.values.where((s) => s.active).map(_toModel).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get all students including inactive
  List<Student> getAllIncludingInactive() {
    return _db.studentsBox.values.map(_toModel).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get a student by ID
  Student? getById(String id) {
    final entity = _db.studentsBox.get(id);
    return entity != null ? _toModel(entity) : null;
  }

  /// Create a new student
  Future<Student> create({
    required String name,
    required String gradeLevel,
    String? avatarColor,
  }) async {
    final entity = StudentEntity.create(
      name: name,
      gradeLevel: gradeLevel,
      avatarColor: avatarColor ??
          AvatarColors.all[_db.studentsBox.length % AvatarColors.all.length],
    );

    await _db.studentsBox.put(entity.id, entity);
    return _toModel(entity);
  }

  /// Update a student
  Future<Student> update(
    String id, {
    String? name,
    String? gradeLevel,
    String? avatarColor,
    bool? active,
  }) async {
    final entity = _db.studentsBox.get(id);
    if (entity == null) {
      throw Exception('Student not found: $id');
    }

    if (name != null) entity.name = name;
    if (gradeLevel != null) entity.gradeLevel = gradeLevel;
    if (avatarColor != null) entity.avatarColor = avatarColor;
    if (active != null) entity.active = active;
    entity.updatedAt = DateTime.now();
    entity.needsSync = true;

    await entity.save();
    return _toModel(entity);
  }

  /// Soft delete a student (set active = false)
  Future<void> delete(String id) async {
    await update(id, active: false);
  }

  /// Hard delete a student (permanent)
  Future<void> hardDelete(String id) async {
    await _db.studentsBox.delete(id);
  }

  /// Get students that need syncing
  List<StudentEntity> getPendingSync() {
    return _db.studentsBox.values.where((s) => s.needsSync).toList();
  }

  /// Mark a student as synced
  Future<void> markSynced(String id, String remoteId) async {
    final entity = _db.studentsBox.get(id);
    if (entity != null) {
      entity.remoteId = remoteId;
      entity.needsSync = false;
      entity.lastSyncedAt = DateTime.now();
      await entity.save();
    }
  }

  /// Import a student from remote (during sync)
  Future<void> importFromRemote(Map<String, dynamic> json) async {
    final entity = StudentEntity.fromJson(json);
    entity.needsSync = false;
    entity.lastSyncedAt = DateTime.now();
    entity.remoteId = json['id'] as String;
    await _db.studentsBox.put(entity.id, entity);
  }

  /// Convert entity to model
  Student _toModel(StudentEntity entity) {
    return Student(
      id: entity.id,
      familyId: entity.familyId,
      name: entity.name,
      gradeLevel: entity.gradeLevel,
      userId: entity.userId,
      avatarColor: entity.avatarColor,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
