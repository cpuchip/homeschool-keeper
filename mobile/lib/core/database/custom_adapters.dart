import 'package:hive/hive.dart';
import 'hive_entities.dart';

/// Custom migration-safe adapter for FamilySettingsEntity
/// This adapter handles null values from old schema versions gracefully
/// by providing sensible defaults.
/// 
/// SCHEMA VERSION HISTORY:
/// v1: Initial - fields 0-8
/// v2: Added autoBackupEnabled (field 9)
class MigrationSafeFamilySettingsAdapter extends TypeAdapter<FamilySettingsEntity> {
  @override
  final int typeId = HiveTypeIds.familySettings;

  @override
  FamilySettingsEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    final now = DateTime.now();
    final year = now.month >= 7 ? now.year : now.year - 1;
    
    return FamilySettingsEntity()
      ..id = fields[0] as String? ?? 'default'
      ..hourIncrement = (fields[1] as num?)?.toDouble() ?? 0.25
      ..currentSchoolYear = fields[2] as String? ?? '$year-${year + 1}'
      ..annualTargetHours = (fields[3] as num?)?.toDouble() ?? 1000.0
      ..state = fields[4] as String? ?? 'MO'
      ..createdAt = fields[5] as DateTime? ?? now
      ..updatedAt = fields[6] as DateTime? ?? now
      ..remoteId = fields[7] as String?
      ..needsSync = fields[8] as bool? ?? true
      ..autoBackupEnabled = fields[9] as bool? ?? true; // New in v2, default to true
  }

  @override
  void write(BinaryWriter writer, FamilySettingsEntity obj) {
    writer
      ..writeByte(10) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hourIncrement)
      ..writeByte(2)
      ..write(obj.currentSchoolYear)
      ..writeByte(3)
      ..write(obj.annualTargetHours)
      ..writeByte(4)
      ..write(obj.state)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.remoteId)
      ..writeByte(8)
      ..write(obj.needsSync)
      ..writeByte(9)
      ..write(obj.autoBackupEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MigrationSafeFamilySettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Custom migration-safe adapter for SyncMetaEntity
class MigrationSafeSyncMetaAdapter extends TypeAdapter<SyncMetaEntity> {
  @override
  final int typeId = HiveTypeIds.syncMeta;

  @override
  SyncMetaEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return SyncMetaEntity()
      ..id = fields[0] as String? ?? 'default'
      ..lastFullSync = fields[1] as DateTime?
      ..pendingChangesCount = fields[2] as int? ?? 0
      ..accountEmail = fields[3] as String?
      ..hasAccount = fields[4] as bool? ?? false;
  }

  @override
  void write(BinaryWriter writer, SyncMetaEntity obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lastFullSync)
      ..writeByte(2)
      ..write(obj.pendingChangesCount)
      ..writeByte(3)
      ..write(obj.accountEmail)
      ..writeByte(4)
      ..write(obj.hasAccount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MigrationSafeSyncMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Custom migration-safe adapter for StudentEntity
class MigrationSafeStudentAdapter extends TypeAdapter<StudentEntity> {
  @override
  final int typeId = HiveTypeIds.student;

  @override
  StudentEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    final now = DateTime.now();
    
    return StudentEntity()
      ..id = fields[0] as String? ?? ''
      ..familyId = fields[1] as String? ?? 'local'
      ..name = fields[2] as String? ?? 'Unknown'
      ..gradeLevel = fields[3] as String? ?? 'Not Set'
      ..userId = fields[4] as String?
      ..avatarColor = fields[5] as String?
      ..active = fields[6] as bool? ?? true
      ..createdAt = fields[7] as DateTime? ?? now
      ..updatedAt = fields[8] as DateTime? ?? now
      ..remoteId = fields[9] as String?
      ..needsSync = fields[10] as bool? ?? true
      ..lastSyncedAt = fields[11] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, StudentEntity obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.familyId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.gradeLevel)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.avatarColor)
      ..writeByte(6)
      ..write(obj.active)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.remoteId)
      ..writeByte(10)
      ..write(obj.needsSync)
      ..writeByte(11)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MigrationSafeStudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Custom migration-safe adapter for SubjectEntity
class MigrationSafeSubjectAdapter extends TypeAdapter<SubjectEntity> {
  @override
  final int typeId = HiveTypeIds.subject;

  @override
  SubjectEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    final now = DateTime.now();
    
    return SubjectEntity()
      ..id = fields[0] as String? ?? ''
      ..familyId = fields[1] as String? ?? 'local'
      ..name = fields[2] as String? ?? 'Unknown'
      ..type = fields[3] as String? ?? 'core'
      ..targetHours = (fields[4] as num?)?.toDouble()
      ..color = fields[5] as String? ?? '#3B82F6'
      ..isDefault = fields[6] as bool? ?? false
      ..sortOrder = fields[7] as int? ?? 0
      ..active = fields[8] as bool? ?? true
      ..createdAt = fields[9] as DateTime? ?? now
      ..updatedAt = fields[10] as DateTime? ?? now
      ..remoteId = fields[11] as String?
      ..needsSync = fields[12] as bool? ?? true
      ..lastSyncedAt = fields[13] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, SubjectEntity obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.familyId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.targetHours)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.isDefault)
      ..writeByte(7)
      ..write(obj.sortOrder)
      ..writeByte(8)
      ..write(obj.active)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.remoteId)
      ..writeByte(12)
      ..write(obj.needsSync)
      ..writeByte(13)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MigrationSafeSubjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Custom migration-safe adapter for LogEntryEntity
class MigrationSafeLogEntryAdapter extends TypeAdapter<LogEntryEntity> {
  @override
  final int typeId = HiveTypeIds.logEntry;

  @override
  LogEntryEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    final now = DateTime.now();
    
    return LogEntryEntity()
      ..id = fields[0] as String? ?? ''
      ..familyId = fields[1] as String? ?? 'local'
      ..organizationId = fields[2] as String?
      ..studentId = fields[3] as String? ?? ''
      ..subjectId = fields[4] as String? ?? ''
      ..groupId = fields[5] as String?
      ..date = fields[6] as DateTime? ?? now
      ..hours = (fields[7] as num?)?.toDouble() ?? 0.0
      ..description = fields[8] as String? ?? ''
      ..locationType = fields[9] as String? ?? 'home'
      ..locationId = fields[10] as String?
      ..locationName = fields[11] as String?
      ..submittedBy = fields[12] as String? ?? 'parent'
      ..status = fields[13] as String? ?? 'approved'
      ..schoolYear = fields[14] as String? ?? _computeSchoolYear(now)
      ..createdAt = fields[15] as DateTime? ?? now
      ..updatedAt = fields[16] as DateTime? ?? now
      ..remoteId = fields[17] as String?
      ..needsSync = fields[18] as bool? ?? true
      ..lastSyncedAt = fields[19] as DateTime?;
  }
  
  static String _computeSchoolYear(DateTime date) {
    final year = date.month >= 7 ? date.year : date.year - 1;
    return '$year-${year + 1}';
  }

  @override
  void write(BinaryWriter writer, LogEntryEntity obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.familyId)
      ..writeByte(2)
      ..write(obj.organizationId)
      ..writeByte(3)
      ..write(obj.studentId)
      ..writeByte(4)
      ..write(obj.subjectId)
      ..writeByte(5)
      ..write(obj.groupId)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.hours)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.locationType)
      ..writeByte(10)
      ..write(obj.locationId)
      ..writeByte(11)
      ..write(obj.locationName)
      ..writeByte(12)
      ..write(obj.submittedBy)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.schoolYear)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.remoteId)
      ..writeByte(18)
      ..write(obj.needsSync)
      ..writeByte(19)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MigrationSafeLogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
