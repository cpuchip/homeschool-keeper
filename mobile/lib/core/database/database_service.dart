import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'hive_entities.dart';

/// Database service for initializing and managing Hive boxes
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  late Box<StudentEntity> studentsBox;
  late Box<SubjectEntity> subjectsBox;
  late Box<LogEntryEntity> logEntriesBox;
  late Box<FamilySettingsEntity> familySettingsBox;
  late Box<SyncMetaEntity> syncMetaBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize Hive and open all boxes
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize Hive with Flutter path
    await Hive.initFlutter();

    // Register adapters
    _registerAdapters();

    // Open boxes
    studentsBox = await Hive.openBox<StudentEntity>(HiveBoxNames.students);
    subjectsBox = await Hive.openBox<SubjectEntity>(HiveBoxNames.subjects);
    logEntriesBox = await Hive.openBox<LogEntryEntity>(HiveBoxNames.logEntries);
    familySettingsBox = await Hive.openBox<FamilySettingsEntity>(HiveBoxNames.familySettings);
    syncMetaBox = await Hive.openBox<SyncMetaEntity>(HiveBoxNames.syncMeta);

    // Ensure default settings exist
    await _ensureDefaults();

    _initialized = true;
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTypeIds.student)) {
      Hive.registerAdapter(StudentEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.subject)) {
      Hive.registerAdapter(SubjectEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.logEntry)) {
      Hive.registerAdapter(LogEntryEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.familySettings)) {
      Hive.registerAdapter(FamilySettingsEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncMeta)) {
      Hive.registerAdapter(SyncMetaEntityAdapter());
    }
  }

  /// Ensure default settings exist
  Future<void> _ensureDefaults() async {
    // Create default family settings if none exist
    if (familySettingsBox.isEmpty) {
      await familySettingsBox.put('default', FamilySettingsEntity.createDefault());
    }

    // Create sync meta if none exists
    if (syncMetaBox.isEmpty) {
      await syncMetaBox.put('sync_meta', SyncMetaEntity.createDefault());
    }

    // Create default subjects if none exist (first-time setup)
    if (subjectsBox.isEmpty) {
      await _createDefaultSubjects();
    }
  }

  /// Create default Missouri-required subjects
  Future<void> _createDefaultSubjects() async {
    final defaultSubjects = [
      // Core subjects (required by Missouri)
      SubjectEntity.create(
        name: 'Reading',
        type: 'core',
        color: '#3B82F6',
        isDefault: true,
        sortOrder: 1,
      ),
      SubjectEntity.create(
        name: 'Math',
        type: 'core',
        color: '#10B981',
        isDefault: true,
        sortOrder: 2,
      ),
      SubjectEntity.create(
        name: 'Social Studies',
        type: 'core',
        color: '#F59E0B',
        isDefault: true,
        sortOrder: 3,
      ),
      SubjectEntity.create(
        name: 'Language Arts',
        type: 'core',
        color: '#8B5CF6',
        isDefault: true,
        sortOrder: 4,
      ),
      SubjectEntity.create(
        name: 'Science',
        type: 'core',
        color: '#06B6D4',
        isDefault: true,
        sortOrder: 5,
      ),
      // Common electives
      SubjectEntity.create(
        name: 'Art',
        type: 'elective',
        color: '#EC4899',
        isDefault: true,
        sortOrder: 6,
      ),
      SubjectEntity.create(
        name: 'Music',
        type: 'elective',
        color: '#F97316',
        isDefault: true,
        sortOrder: 7,
      ),
      SubjectEntity.create(
        name: 'Physical Education',
        type: 'elective',
        color: '#EF4444',
        isDefault: true,
        sortOrder: 8,
      ),
    ];

    for (final subject in defaultSubjects) {
      await subjectsBox.put(subject.id, subject);
    }
  }

  /// Get family settings
  FamilySettingsEntity get familySettings =>
      familySettingsBox.get('default') ?? FamilySettingsEntity.createDefault();

  /// Get sync metadata
  SyncMetaEntity get syncMeta =>
      syncMetaBox.get('sync_meta') ?? SyncMetaEntity.createDefault();

  /// Check if user has an account (for optional sync)
  bool get hasAccount => syncMeta.hasAccount;

  /// Get count of pending changes to sync
  int get pendingChangesCount {
    int count = 0;
    count += studentsBox.values.where((s) => s.needsSync).length;
    count += subjectsBox.values.where((s) => s.needsSync).length;
    count += logEntriesBox.values.where((l) => l.needsSync).length;
    return count;
  }

  /// Close all boxes
  Future<void> close() async {
    await studentsBox.close();
    await subjectsBox.close();
    await logEntriesBox.close();
    await familySettingsBox.close();
    await syncMetaBox.close();
    _initialized = false;
  }

  /// Clear all data (for debugging or account deletion)
  Future<void> clearAll() async {
    await studentsBox.clear();
    await subjectsBox.clear();
    await logEntriesBox.clear();
    await familySettingsBox.clear();
    await syncMetaBox.clear();
    await _ensureDefaults();
  }

  /// Get backup directory path for dead man's switch exports
  Future<Directory> getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${documentsDir.path}/HomeSchoolLogs/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Get external backup directory (accessible to user)
  Future<Directory?> getExternalBackupDirectory() async {
    try {
      // Try to get external storage (Android Documents folder)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Navigate to Documents folder
        final documentsPath = externalDir.path.replaceAll(
          RegExp(r'/Android/data/[^/]+/files'),
          '/Documents/HomeSchoolLogs',
        );
        final backupDir = Directory(documentsPath);
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        return backupDir;
      }
    } catch (e) {
      // Fall back to internal backup directory
      return await getBackupDirectory();
    }
    return null;
  }
}
