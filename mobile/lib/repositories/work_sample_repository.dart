import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/work_sample.dart';

/// Repository for managing work samples with local-first storage.
///
/// Files are stored locally in the backup directory first.
/// If sync is enabled, they are uploaded to R2 in the background.
class WorkSampleRepository {
  static const String _boxName = 'work_samples';
  late Box<Map<dynamic, dynamic>> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  /// Get the local storage directory for work samples
  Future<Directory> get localStorageDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(appDir.path, 'HomeSchoolLogs', 'work_samples'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Save a file locally and create a work sample record
  Future<WorkSample> saveLocally({
    required String logEntryId,
    String? groupId,
    required String studentId,
    required File file,
    required String contentType,
    String? description,
    required String uploadedBy,
    required String familyId,
  }) async {
    // Generate unique ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Copy file to local storage
    final storageDir = await localStorageDir;
    final fileName = path.basename(file.path);
    final localPath = path.join(storageDir.path, logEntryId, '${id}_$fileName');
    
    // Ensure directory exists
    await Directory(path.dirname(localPath)).create(recursive: true);
    
    // Copy file
    await file.copy(localPath);
    
    // Get file size
    final fileSize = await file.length();
    
    // Create work sample record
    final sample = WorkSample(
      id: id,
      familyId: familyId,
      logEntryId: logEntryId,
      groupId: groupId,
      studentId: studentId,
      fileName: fileName,
      localPath: localPath,
      contentType: contentType,
      sizeBytes: fileSize,
      uploadedBy: uploadedBy,
      description: description,
      syncStatus: SyncStatus.local,
      createdAt: DateTime.now(),
    );
    
    // Save to Hive
    await _box.put(id, sample.toJson());
    
    return sample;
  }

  /// Get all work samples for a log entry
  List<WorkSample> getByLogEntry(String logEntryId, {String? groupId}) {
    return _box.values
        .map((json) => WorkSample.fromJson(Map<String, dynamic>.from(json)))
        .where((s) {
          if (groupId != null && s.groupId == groupId) return true;
          return s.logEntryId == logEntryId;
        })
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get all work samples for a student
  List<WorkSample> getByStudent(String studentId) {
    return _box.values
        .map((json) => WorkSample.fromJson(Map<String, dynamic>.from(json)))
        .where((s) => s.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all work samples pending sync
  List<WorkSample> getPendingSync() {
    return _box.values
        .map((json) => WorkSample.fromJson(Map<String, dynamic>.from(json)))
        .where((s) => s.syncStatus == SyncStatus.local || s.syncStatus == SyncStatus.error)
        .toList();
  }

  /// Get a work sample by ID
  WorkSample? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return WorkSample.fromJson(Map<String, dynamic>.from(json));
  }

  /// Update sync status
  Future<void> updateSyncStatus(String id, SyncStatus status, {String? storageKey}) async {
    final sample = getById(id);
    if (sample == null) return;
    
    final updated = sample.copyWith(
      syncStatus: status,
      storageKey: storageKey ?? sample.storageKey,
    );
    await _box.put(id, updated.toJson());
  }

  /// Delete a work sample (both record and local file)
  Future<void> delete(String id) async {
    final sample = getById(id);
    if (sample == null) return;
    
    // Delete local file
    if (sample.localPath != null) {
      final file = File(sample.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    // Delete record
    await _box.delete(id);
  }

  /// Get total local storage used
  Future<int> getLocalStorageUsed() async {
    int total = 0;
    for (final json in _box.values) {
      final sample = WorkSample.fromJson(Map<String, dynamic>.from(json));
      total += sample.sizeBytes;
    }
    return total;
  }

  /// Get count of work samples
  int get count => _box.length;

  /// Clear all work samples (for logout/account switch)
  Future<void> clear() async {
    // Delete all local files
    for (final json in _box.values) {
      final sample = WorkSample.fromJson(Map<String, dynamic>.from(json));
      if (sample.localPath != null) {
        final file = File(sample.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await _box.clear();
  }
}
