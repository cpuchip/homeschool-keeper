import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_service.dart';

/// Dead man's switch - automatic failsafe backup service
/// 
/// This service periodically saves a backup to a user-accessible location
/// on the device's file system. If the app crashes or becomes unresponsive,
/// users can still recover their data from these backup files.
class FailsafeBackupService {
  static FailsafeBackupService? _instance;
  static FailsafeBackupService get instance =>
      _instance ??= FailsafeBackupService._();

  FailsafeBackupService._();

  Timer? _backupTimer;
  bool _isRunning = false;

  /// Backup interval (default: every 15 minutes)
  static const Duration backupInterval = Duration(minutes: 15);

  /// Maximum number of backup files to keep
  static const int maxBackupFiles = 5;

  /// Start the automatic backup timer
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Perform immediate backup on start
    _performBackup();

    // Schedule periodic backups
    _backupTimer = Timer.periodic(backupInterval, (_) {
      _performBackup();
    });

    debugPrint('FailsafeBackupService: Started (interval: $backupInterval)');
  }

  /// Stop the automatic backup timer
  void stop() {
    _backupTimer?.cancel();
    _backupTimer = null;
    _isRunning = false;
    debugPrint('FailsafeBackupService: Stopped');
  }

  /// Perform a backup now (can be called manually)
  Future<String?> performBackupNow() async {
    return await _performBackup();
  }

  /// Internal backup method
  Future<String?> _performBackup() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) {
        debugPrint('FailsafeBackupService: Database not initialized, skipping');
        return null;
      }

      // Gather all data
      final data = _gatherBackupData(db);

      // Get backup directory
      final backupDir = await _getBackupDirectory();
      if (backupDir == null) {
        debugPrint('FailsafeBackupService: Could not get backup directory');
        return null;
      }

      // Create backup file
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final fileName = 'failsafe_backup_$timestamp.json';
      final filePath = '${backupDir.path}/$fileName';

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final file = File(filePath);
      await file.writeAsString(jsonString);

      debugPrint('FailsafeBackupService: Backup saved to $filePath');

      // Cleanup old backups
      await _cleanupOldBackups(backupDir);

      return filePath;
    } catch (e) {
      debugPrint('FailsafeBackupService: Backup failed - $e');
      return null;
    }
  }

  /// Gather all data for backup
  Map<String, dynamic> _gatherBackupData(DatabaseService db) {
    final students = db.studentsBox.values.map((s) => s.toJson()).toList();
    final subjects = db.subjectsBox.values.map((s) => s.toJson()).toList();
    final logs = db.logEntriesBox.values.map((l) => l.toJson()).toList();

    final settings = {
      'hourIncrement': db.familySettings.hourIncrement,
      'currentSchoolYear': db.familySettings.currentSchoolYear,
      'annualTargetHours': db.familySettings.annualTargetHours,
      'state': db.familySettings.state,
    };

    return {
      'backupVersion': 1,
      'backupType': 'failsafe',
      'backupedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'settings': settings,
      'students': students,
      'subjects': subjects,
      'logs': logs,
      'metadata': {
        'studentCount': students.length,
        'subjectCount': subjects.length,
        'logCount': logs.length,
      },
    };
  }

  /// Get the external backup directory (accessible to users)
  Future<Directory?> _getBackupDirectory() async {
    try {
      // Try external storage first (more accessible to users)
      Directory? backupDir;

      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to a more accessible location
          // From: /storage/emulated/0/Android/data/com.example.app/files
          // To:   /storage/emulated/0/Documents/HomeSchoolLogs
          final basePath = externalDir.path.split('/Android/data').first;
          backupDir = Directory('$basePath/Documents/HomeSchoolLogs/backups');
        }
      }

      // Fallback to app documents directory
      backupDir ??= Directory(
        '${(await getApplicationDocumentsDirectory()).path}/HomeSchoolLogs',
      );

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      return backupDir;
    } catch (e) {
      debugPrint('FailsafeBackupService: Error getting backup directory - $e');
      return null;
    }
  }

  /// Remove old backup files, keeping only the most recent ones
  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('failsafe_backup_'))
          .toList();

      if (files.length <= maxBackupFiles) return;

      // Sort by modification time (oldest first)
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );

      // Delete oldest files
      final filesToDelete = files.take(files.length - maxBackupFiles);
      for (final file in filesToDelete) {
        await file.delete();
        debugPrint('FailsafeBackupService: Deleted old backup ${file.path}');
      }
    } catch (e) {
      debugPrint('FailsafeBackupService: Cleanup error - $e');
    }
  }

  /// Get the latest backup file path
  Future<String?> getLatestBackupPath() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (backupDir == null) return null;

      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('failsafe_backup_'))
          .toList();

      if (files.isEmpty) return null;

      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      return files.first.path;
    } catch (e) {
      return null;
    }
  }

  /// List all failsafe backup files
  Future<List<BackupFileInfo>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (backupDir == null) return [];

      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('failsafe_backup_'))
          .toList();

      final backups = <BackupFileInfo>[];
      for (final file in files) {
        try {
          final stat = await file.stat();
          backups.add(
            BackupFileInfo(
              path: file.path,
              fileName: file.path.split('/').last,
              size: stat.size,
              modifiedAt: stat.modified,
            ),
          );
        } catch (_) {}
      }

      backups.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return backups;
    } catch (e) {
      return [];
    }
  }
}

/// Information about a backup file
class BackupFileInfo {
  final String path;
  final String fileName;
  final int size;
  final DateTime modifiedAt;

  const BackupFileInfo({
    required this.path,
    required this.fileName,
    required this.size,
    required this.modifiedAt,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
