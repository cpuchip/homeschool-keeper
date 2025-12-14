import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'hive_entities.g.dart';

/// Type IDs for Hive adapters
/// Keep these constant - changing them will break existing databases!
class HiveTypeIds {
  static const int student = 0;
  static const int subject = 1;
  static const int logEntry = 2;
  static const int familySettings = 3;
  static const int syncMeta = 4;
}

/// Box names for Hive storage
class HiveBoxNames {
  static const String students = 'students';
  static const String subjects = 'subjects';
  static const String logEntries = 'log_entries';
  static const String familySettings = 'family_settings';
  static const String syncQueue = 'sync_queue';
  static const String syncMeta = 'sync_meta';
}

/// Student entity for Hive storage
@HiveType(typeId: HiveTypeIds.student)
class StudentEntity extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String familyId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String gradeLevel;

  @HiveField(4)
  String? userId;

  @HiveField(5)
  String? avatarColor;

  @HiveField(6)
  late bool active;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late DateTime updatedAt;

  /// Sync tracking
  @HiveField(9)
  String? remoteId; // ID from server (if synced)

  @HiveField(10)
  late bool needsSync; // Has local changes not yet synced

  @HiveField(11)
  DateTime? lastSyncedAt;

  StudentEntity();

  factory StudentEntity.create({
    required String name,
    required String gradeLevel,
    String? userId,
    String? avatarColor,
  }) {
    final now = DateTime.now();
    return StudentEntity()
      ..id = const Uuid().v4()
      ..familyId = 'local' // Will be updated if user syncs
      ..name = name
      ..gradeLevel = gradeLevel
      ..userId = userId
      ..avatarColor = avatarColor
      ..active = true
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = true
      ..lastSyncedAt = null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'familyId': familyId,
        'name': name,
        'gradeLevel': gradeLevel,
        'userId': userId,
        'avatarColor': avatarColor,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StudentEntity.fromJson(Map<String, dynamic> json) {
    return StudentEntity()
      ..id = json['id'] as String
      ..familyId = json['familyId'] as String
      ..name = json['name'] as String
      ..gradeLevel = json['gradeLevel'] as String
      ..userId = json['userId'] as String?
      ..avatarColor = json['avatarColor'] as String?
      ..active = json['active'] as bool
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..needsSync = false
      ..lastSyncedAt = DateTime.now();
  }
}

/// Subject entity for Hive storage
@HiveType(typeId: HiveTypeIds.subject)
class SubjectEntity extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String familyId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String type; // core, elective

  @HiveField(4)
  double? targetHours;

  @HiveField(5)
  late String color;

  @HiveField(6)
  late bool isDefault;

  @HiveField(7)
  late int sortOrder;

  @HiveField(8)
  late bool active;

  @HiveField(9)
  late DateTime createdAt;

  @HiveField(10)
  late DateTime updatedAt;

  /// Sync tracking
  @HiveField(11)
  String? remoteId;

  @HiveField(12)
  late bool needsSync;

  @HiveField(13)
  DateTime? lastSyncedAt;

  SubjectEntity();

  factory SubjectEntity.create({
    required String name,
    required String type,
    double? targetHours,
    required String color,
    bool isDefault = false,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return SubjectEntity()
      ..id = const Uuid().v4()
      ..familyId = 'local'
      ..name = name
      ..type = type
      ..targetHours = targetHours
      ..color = color
      ..isDefault = isDefault
      ..sortOrder = sortOrder
      ..active = true
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = true
      ..lastSyncedAt = null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'familyId': familyId,
        'name': name,
        'type': type,
        'targetHours': targetHours,
        'color': color,
        'isDefault': isDefault,
        'sortOrder': sortOrder,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SubjectEntity.fromJson(Map<String, dynamic> json) {
    return SubjectEntity()
      ..id = json['id'] as String
      ..familyId = json['familyId'] as String
      ..name = json['name'] as String
      ..type = json['type'] as String
      ..targetHours = (json['targetHours'] as num?)?.toDouble()
      ..color = json['color'] as String
      ..isDefault = json['isDefault'] as bool
      ..sortOrder = json['sortOrder'] as int
      ..active = json['active'] as bool
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..needsSync = false
      ..lastSyncedAt = DateTime.now();
  }
}

/// Log entry entity for Hive storage
@HiveType(typeId: HiveTypeIds.logEntry)
class LogEntryEntity extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String familyId;

  @HiveField(2)
  String? organizationId;

  @HiveField(3)
  late String studentId;

  @HiveField(4)
  late String subjectId;

  @HiveField(5)
  late DateTime date;

  @HiveField(6)
  late double hours;

  @HiveField(7)
  late String description;

  @HiveField(8)
  late String locationType;

  @HiveField(9)
  String? locationId;

  @HiveField(10)
  String? locationName;

  @HiveField(11)
  late String submittedBy;

  @HiveField(12)
  late String status;

  @HiveField(13)
  late String schoolYear;

  @HiveField(14)
  late DateTime createdAt;

  @HiveField(15)
  late DateTime updatedAt;

  /// Sync tracking
  @HiveField(16)
  String? remoteId;

  @HiveField(17)
  late bool needsSync;

  @HiveField(18)
  DateTime? lastSyncedAt;

  /// Group ID for multi-student log entries (created together)
  @HiveField(19)
  String? groupId;

  LogEntryEntity();

  factory LogEntryEntity.create({
    required String studentId,
    required String subjectId,
    required DateTime date,
    required double hours,
    required String description,
    required String locationType,
    String? locationId,
    String? locationName,
    String? schoolYear,
    String? groupId,
  }) {
    final now = DateTime.now();
    // Calculate school year: if before July, it's previous year
    final year = date.month >= 7 ? date.year : date.year - 1;
    final computedSchoolYear = schoolYear ?? '$year-${year + 1}';

    return LogEntryEntity()
      ..id = const Uuid().v4()
      ..familyId = 'local'
      ..studentId = studentId
      ..subjectId = subjectId
      ..groupId = groupId
      ..date = date
      ..hours = hours
      ..description = description
      ..locationType = locationType
      ..locationId = locationId
      ..locationName = locationName
      ..submittedBy = 'local_user'
      ..status = 'approved'
      ..schoolYear = computedSchoolYear
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = true
      ..lastSyncedAt = null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'familyId': familyId,
        'organizationId': organizationId,
        'studentId': studentId,
        'subjectId': subjectId,
        'groupId': groupId,
        'date': date.toIso8601String(),
        'hours': hours,
        'description': description,
        'locationType': locationType,
        'locationId': locationId,
        'locationName': locationName,
        'submittedBy': submittedBy,
        'status': status,
        'schoolYear': schoolYear,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LogEntryEntity.fromJson(Map<String, dynamic> json) {
    return LogEntryEntity()
      ..id = json['id'] as String
      ..familyId = json['familyId'] as String
      ..organizationId = json['organizationId'] as String?
      ..studentId = json['studentId'] as String
      ..subjectId = json['subjectId'] as String
      ..groupId = json['groupId'] as String?
      ..date = DateTime.parse(json['date'] as String)
      ..hours = (json['hours'] as num).toDouble()
      ..description = json['description'] as String
      ..locationType = json['locationType'] as String
      ..locationId = json['locationId'] as String?
      ..locationName = json['locationName'] as String?
      ..submittedBy = json['submittedBy'] as String
      ..status = json['status'] as String
      ..schoolYear = json['schoolYear'] as String
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..needsSync = false
      ..lastSyncedAt = DateTime.now();
  }
}

/// Family settings entity for local preferences
@HiveType(typeId: HiveTypeIds.familySettings)
class FamilySettingsEntity extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double hourIncrement; // 0.25, 0.5, 1.0

  @HiveField(2)
  late String currentSchoolYear;

  @HiveField(3)
  late double annualTargetHours; // e.g., 1000 for Missouri

  @HiveField(4)
  late String state; // e.g., 'MO' for Missouri

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  /// Sync tracking
  @HiveField(7)
  String? remoteId;

  @HiveField(8)
  late bool needsSync;

  /// Backup settings
  @HiveField(9)
  late bool autoBackupEnabled; // Enable/disable automatic failsafe backups

  FamilySettingsEntity();

  factory FamilySettingsEntity.createDefault() {
    final now = DateTime.now();
    final year = now.month >= 7 ? now.year : now.year - 1;

    return FamilySettingsEntity()
      ..id = 'default'
      ..hourIncrement = 0.25
      ..currentSchoolYear = '$year-${year + 1}'
      ..annualTargetHours = 1000 // Missouri default
      ..state = 'MO'
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = true
      ..autoBackupEnabled = true; // Enabled by default
  }
}

/// Metadata for sync status
@HiveType(typeId: HiveTypeIds.syncMeta)
class SyncMetaEntity extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  DateTime? lastFullSync;

  @HiveField(2)
  late int pendingChangesCount;

  @HiveField(3)
  String? accountEmail; // null = no account (offline-only mode)

  @HiveField(4)
  late bool hasAccount;

  SyncMetaEntity();

  factory SyncMetaEntity.createDefault() {
    return SyncMetaEntity()
      ..id = 'sync_meta'
      ..lastFullSync = null
      ..pendingChangesCount = 0
      ..accountEmail = null
      ..hasAccount = false;
  }
}
