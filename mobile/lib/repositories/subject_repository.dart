import '../core/database/database_service.dart';
import '../core/database/hive_entities.dart';
import '../models/subject.dart';

/// Local repository for Subject data using Hive
class SubjectRepository {
  final DatabaseService _db;

  SubjectRepository({DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  /// Get all active subjects
  List<Subject> getAll() {
    return _db.subjectsBox.values.where((s) => s.active).map(_toModel).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get all subjects including inactive
  List<Subject> getAllIncludingInactive() {
    return _db.subjectsBox.values.map(_toModel).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get core subjects only
  List<Subject> getCoreSubjects() {
    return _db.subjectsBox.values
        .where((s) => s.active && s.type == 'core')
        .map(_toModel)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get elective subjects only
  List<Subject> getElectiveSubjects() {
    return _db.subjectsBox.values
        .where((s) => s.active && s.type == 'elective')
        .map(_toModel)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get a subject by ID
  Subject? getById(String id) {
    final entity = _db.subjectsBox.get(id);
    return entity != null ? _toModel(entity) : null;
  }

  /// Create a new subject
  Future<Subject> create({
    required String name,
    required String type,
    double? targetHours,
    String? color,
    int? sortOrder,
  }) async {
    final entity = SubjectEntity.create(
      name: name,
      type: type,
      targetHours: targetHours,
      color: color ??
          SubjectColors.all[_db.subjectsBox.length % SubjectColors.all.length],
      sortOrder: sortOrder ?? _db.subjectsBox.length,
    );

    await _db.subjectsBox.put(entity.id, entity);
    return _toModel(entity);
  }

  /// Update a subject
  Future<Subject> update(
    String id, {
    String? name,
    String? type,
    double? targetHours,
    String? color,
    int? sortOrder,
    bool? active,
  }) async {
    final entity = _db.subjectsBox.get(id);
    if (entity == null) {
      throw Exception('Subject not found: $id');
    }

    if (name != null) entity.name = name;
    if (type != null) entity.type = type;
    if (targetHours != null) entity.targetHours = targetHours;
    if (color != null) entity.color = color;
    if (sortOrder != null) entity.sortOrder = sortOrder;
    if (active != null) entity.active = active;
    entity.updatedAt = DateTime.now();
    entity.needsSync = true;

    await entity.save();
    return _toModel(entity);
  }

  /// Soft delete a subject
  Future<void> delete(String id) async {
    await update(id, active: false);
  }

  /// Hard delete a subject
  Future<void> hardDelete(String id) async {
    await _db.subjectsBox.delete(id);
  }

  /// Get subjects that need syncing
  List<SubjectEntity> getPendingSync() {
    return _db.subjectsBox.values.where((s) => s.needsSync).toList();
  }

  /// Mark a subject as synced
  Future<void> markSynced(String id, String remoteId) async {
    final entity = _db.subjectsBox.get(id);
    if (entity != null) {
      entity.remoteId = remoteId;
      entity.needsSync = false;
      entity.lastSyncedAt = DateTime.now();
      await entity.save();
    }
  }

  /// Import a subject from remote
  Future<void> importFromRemote(Map<String, dynamic> json) async {
    final entity = SubjectEntity.fromJson(json);
    entity.needsSync = false;
    entity.lastSyncedAt = DateTime.now();
    entity.remoteId = json['id'] as String;
    await _db.subjectsBox.put(entity.id, entity);
  }

  /// Convert entity to model
  Subject _toModel(SubjectEntity entity) {
    return Subject(
      id: entity.id,
      familyId: entity.familyId,
      name: entity.name,
      type: entity.type,
      targetHours: entity.targetHours,
      color: entity.color,
      isDefault: entity.isDefault,
      sortOrder: entity.sortOrder,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
