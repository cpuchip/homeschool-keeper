import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_sample.freezed.dart';
part 'work_sample.g.dart';

/// Sync status for work samples
enum SyncStatus {
  @JsonValue('local')
  local, // Stored locally only
  @JsonValue('syncing')
  syncing, // Currently uploading
  @JsonValue('synced')
  synced, // Uploaded to R2
  @JsonValue('error')
  error, // Upload failed
}

/// A work sample (photo, document, etc.) attached to a log entry.
/// 
/// For offline-first mobile:
/// 1. Files are stored locally first in the backup directory
/// 2. If sync is enabled, files are uploaded to R2 when on good network
/// 3. [localPath] stores the local file path
/// 4. [storageKey] stores the R2 object key (after sync)
@freezed
class WorkSample with _$WorkSample {
  const factory WorkSample({
    required String id,
    required String familyId,
    required String logEntryId,
    String? groupId, // Links to all logs in a multi-student group
    required String studentId,
    required String fileName,
    String? localPath, // Local file path (for offline storage)
    String? storageKey, // R2 object key (after sync)
    required String contentType,
    required int sizeBytes,
    required String uploadedBy,
    String? description,
    @Default(SyncStatus.local) SyncStatus syncStatus,
    String? downloadUrl, // Pre-signed URL for viewing
    String? expiresAt, // URL expiration
    required DateTime createdAt,
  }) = _WorkSample;

  factory WorkSample.fromJson(Map<String, dynamic> json) =>
      _$WorkSampleFromJson(json);
}

/// Premium features for a family
@freezed
class PremiumFeatures with _$PremiumFeatures {
  const factory PremiumFeatures({
    @Default(false) bool syncEnabled,
    @Default(false) bool uploadsEnabled,
    @Default(0) int storageUsedBytes,
    @Default(104857600) int storageLimitBytes, // 100MB default
    @Default('free') String subscriptionTier,
    DateTime? subscriptionEnd,
  }) = _PremiumFeatures;

  factory PremiumFeatures.fromJson(Map<String, dynamic> json) =>
      _$PremiumFeaturesFromJson(json);
}

/// Storage usage information
@freezed
class StorageUsage with _$StorageUsage {
  const factory StorageUsage({
    required int usedBytes,
    required int limitBytes,
    required double usedPercent,
    required int fileCount,
    required bool uploadsEnabled,
    required double usedMB,
    required double limitMB,
    required int remainingBytes,
  }) = _StorageUsage;

  factory StorageUsage.fromJson(Map<String, dynamic> json) =>
      _$StorageUsageFromJson(json);
}

/// Response when requesting an upload URL
@freezed
class UploadUrlResponse with _$UploadUrlResponse {
  const factory UploadUrlResponse({
    required String uploadUrl,
    required String workSampleId,
    required String storageKey,
    required String expiresAt,
  }) = _UploadUrlResponse;

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadUrlResponseFromJson(json);
}

/// Allowed content types for work sample uploads
const allowedContentTypes = {
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'image/heic',
  'image/heif',
  'application/pdf',
  'video/mp4',
  'video/quicktime',
};

/// Maximum file size (10MB)
const maxFileSizeBytes = 10 * 1024 * 1024;

/// Check if a content type is allowed
bool isAllowedContentType(String contentType) {
  return allowedContentTypes.contains(contentType);
}
