import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_client.dart';
import '../../models/work_sample.dart';
import '../../repositories/work_sample_repository.dart';

/// Service for managing work sample sync with R2.
///
/// Handles:
/// - Uploading local files to R2 when sync is enabled
/// - Background sync when on good network
/// - Retry logic for failed uploads
class WorkSampleService {
  final ApiClient _api;
  final WorkSampleRepository _repository;

  bool _isSyncing = false;

  StorageUsage? _cachedUsage;
  DateTime? _cachedUsageAt;

  WorkSampleService(this._api, this._repository);

  Future<StorageUsage?> _getStorageUsageCached({Duration ttl = const Duration(minutes: 5)}) async {
    final now = DateTime.now();
    if (_cachedUsage != null && _cachedUsageAt != null && now.difference(_cachedUsageAt!) < ttl) {
      return _cachedUsage;
    }
    final fresh = await getStorageUsage();
    if (fresh != null) {
      _cachedUsage = fresh;
      _cachedUsageAt = now;
    }
    return fresh;
  }

  Future<bool> _uploadsEnabled() async {
    final usage = await _getStorageUsageCached();
    return usage?.uploadsEnabled ?? false;
  }

  /// Sync all pending work samples to R2
  Future<void> syncPendingUploads() async {
    if (_isSyncing) return;

    // Only attempt uploads if the backend says uploads are enabled.
    // (If disabled, we still keep attachments locally.)
    final enabled = await _uploadsEnabled();
    if (!enabled) return;

    // Check network connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.contains(ConnectivityResult.none)) {
      return;
    }

    _isSyncing = true;

    try {
      final pending = _repository.getPendingSync();
      
      for (final sample in pending) {
        await _uploadToR2(sample);
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Upload a single work sample to R2
  Future<void> _uploadToR2(WorkSample sample) async {
    if (sample.localPath == null) return;

    final file = File(sample.localPath!);
    if (!await file.exists()) {
      // Local file missing, mark as error
      await _repository.updateSyncStatus(sample.id, SyncStatus.error);
      return;
    }

    try {
      // Update status to syncing
      await _repository.updateSyncStatus(sample.id, SyncStatus.syncing);

      // Get pre-signed upload URL from backend
      final response = await _api.post('/v1/uploads/url', data: {
        'logEntryId': sample.logEntryId,
        'groupId': sample.groupId,
        'fileName': sample.fileName,
        'contentType': sample.contentType,
        'sizeBytes': sample.sizeBytes,
        'description': sample.description,
      },);

      final uploadUrl = response.data['uploadUrl'] as String;
      final storageKey = response.data['storageKey'] as String;
      final workSampleId = response.data['workSampleId'] as String;

      // Upload file to R2 using pre-signed URL
      final fileBytes = await file.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': sample.contentType,
          'Content-Length': sample.sizeBytes.toString(),
        },
        body: fileBytes,
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Upload failed: ${uploadResponse.statusCode}');
      }

      // Confirm upload with backend
      await _api.post('/v1/uploads/confirm', data: {
        'workSampleId': workSampleId,
      },);

      // Update local record with storage key and synced status
      await _repository.updateSyncStatus(
        sample.id,
        SyncStatus.synced,
        storageKey: storageKey,
      );

    } catch (e) {
      // Mark as error for retry
      await _repository.updateSyncStatus(sample.id, SyncStatus.error);
      rethrow;
    }
  }

  /// Get storage usage from backend
  Future<StorageUsage?> getStorageUsage() async {
    try {
      final response = await _api.get('/v1/uploads/usage');
      return StorageUsage.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Get work samples for a log entry, including synced ones from backend
  Future<List<WorkSample>> getByLogEntry(String logEntryId, {String? groupId}) async {
    // Get local samples
    final local = _repository.getByLogEntry(logEntryId, groupId: groupId);

    // Best-effort: also try to fetch remote samples so attachments created on web
    // can appear on mobile.
    try {
      final response = await _api.get('/v1/logs/$logEntryId/work-samples');
      final remote = (response.data as List)
          .map((json) => WorkSample.fromJson(json as Map<String, dynamic>))
          .toList();

      // Merge: prefer local for matching IDs, add any remote-only
      final localIds = local.map((s) => s.id).toSet();
      final remoteOnly = remote.where((s) => !localIds.contains(s.id)).toList();

      return [...local, ...remoteOnly];
    } catch (e) {
      // Fallback to local only
    }

    return local;
  }

  /// Delete a work sample (local and remote if synced)
  Future<void> delete(String id) async {
    final sample = _repository.getById(id);
    if (sample == null) return;

    // Delete from backend if synced
    if (sample.syncStatus == SyncStatus.synced) {
      try {
        await _api.delete('/v1/work-samples/$id');
      } catch (e) {
        // Continue with local deletion even if remote fails
      }
    }

    // Delete locally
    await _repository.delete(id);
  }
}

/// Provider for work sample repository
final workSampleRepositoryProvider = Provider<WorkSampleRepository>((ref) {
  return WorkSampleRepository();
});

/// Provider for work sample service
final workSampleServiceProvider = Provider<WorkSampleService>((ref) {
  final api = ref.watch(apiClientProvider);
  final repository = ref.watch(workSampleRepositoryProvider);
  return WorkSampleService(api, repository);
});
