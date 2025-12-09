// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_entities.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentEntityAdapter extends TypeAdapter<StudentEntity> {
  @override
  final int typeId = 0;

  @override
  StudentEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentEntity()
      ..id = fields[0] as String
      ..familyId = fields[1] as String
      ..name = fields[2] as String
      ..gradeLevel = fields[3] as String
      ..userId = fields[4] as String?
      ..avatarColor = fields[5] as String?
      ..active = fields[6] as bool
      ..createdAt = fields[7] as DateTime
      ..updatedAt = fields[8] as DateTime
      ..remoteId = fields[9] as String?
      ..needsSync = fields[10] as bool
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
      other is StudentEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubjectEntityAdapter extends TypeAdapter<SubjectEntity> {
  @override
  final int typeId = 1;

  @override
  SubjectEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectEntity()
      ..id = fields[0] as String
      ..familyId = fields[1] as String
      ..name = fields[2] as String
      ..type = fields[3] as String
      ..targetHours = fields[4] as double?
      ..color = fields[5] as String
      ..isDefault = fields[6] as bool
      ..sortOrder = fields[7] as int
      ..active = fields[8] as bool
      ..createdAt = fields[9] as DateTime
      ..updatedAt = fields[10] as DateTime
      ..remoteId = fields[11] as String?
      ..needsSync = fields[12] as bool
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
      other is SubjectEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogEntryEntityAdapter extends TypeAdapter<LogEntryEntity> {
  @override
  final int typeId = 2;

  @override
  LogEntryEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogEntryEntity()
      ..id = fields[0] as String
      ..familyId = fields[1] as String
      ..organizationId = fields[2] as String?
      ..studentId = fields[3] as String
      ..subjectId = fields[4] as String
      ..date = fields[5] as DateTime
      ..hours = fields[6] as double
      ..description = fields[7] as String
      ..locationType = fields[8] as String
      ..locationId = fields[9] as String?
      ..locationName = fields[10] as String?
      ..submittedBy = fields[11] as String
      ..status = fields[12] as String
      ..schoolYear = fields[13] as String
      ..createdAt = fields[14] as DateTime
      ..updatedAt = fields[15] as DateTime
      ..remoteId = fields[16] as String?
      ..needsSync = fields[17] as bool
      ..lastSyncedAt = fields[18] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, LogEntryEntity obj) {
    writer
      ..writeByte(19)
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
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.hours)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.locationType)
      ..writeByte(9)
      ..write(obj.locationId)
      ..writeByte(10)
      ..write(obj.locationName)
      ..writeByte(11)
      ..write(obj.submittedBy)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.schoolYear)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.remoteId)
      ..writeByte(17)
      ..write(obj.needsSync)
      ..writeByte(18)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntryEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FamilySettingsEntityAdapter extends TypeAdapter<FamilySettingsEntity> {
  @override
  final int typeId = 3;

  @override
  FamilySettingsEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FamilySettingsEntity()
      ..id = fields[0] as String
      ..hourIncrement = fields[1] as double
      ..currentSchoolYear = fields[2] as String
      ..annualTargetHours = fields[3] as double
      ..state = fields[4] as String
      ..createdAt = fields[5] as DateTime
      ..updatedAt = fields[6] as DateTime
      ..remoteId = fields[7] as String?
      ..needsSync = fields[8] as bool
      ..autoBackupEnabled = fields[9] as bool? ?? true; // Default to enabled for existing data
  }

  @override
  void write(BinaryWriter writer, FamilySettingsEntity obj) {
    writer
      ..writeByte(10)
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
      other is FamilySettingsEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncMetaEntityAdapter extends TypeAdapter<SyncMetaEntity> {
  @override
  final int typeId = 4;

  @override
  SyncMetaEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetaEntity()
      ..id = fields[0] as String
      ..lastFullSync = fields[1] as DateTime?
      ..pendingChangesCount = fields[2] as int
      ..accountEmail = fields[3] as String?
      ..hasAccount = fields[4] as bool;
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
      other is SyncMetaEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
