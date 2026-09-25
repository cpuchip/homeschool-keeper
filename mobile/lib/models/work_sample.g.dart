// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_sample.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkSampleImpl _$$WorkSampleImplFromJson(Map<String, dynamic> json) =>
    _$WorkSampleImpl(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      logEntryId: json['logEntryId'] as String,
      groupId: json['groupId'] as String?,
      studentId: json['studentId'] as String,
      fileName: json['fileName'] as String,
      localPath: json['localPath'] as String?,
      storageKey: json['storageKey'] as String?,
      contentType: json['contentType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      uploadedBy: json['uploadedBy'] as String,
      description: json['description'] as String?,
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
              SyncStatus.local,
      downloadUrl: json['downloadUrl'] as String?,
      expiresAt: json['expiresAt'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WorkSampleImplToJson(_$WorkSampleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'logEntryId': instance.logEntryId,
      'groupId': instance.groupId,
      'studentId': instance.studentId,
      'fileName': instance.fileName,
      'localPath': instance.localPath,
      'storageKey': instance.storageKey,
      'contentType': instance.contentType,
      'sizeBytes': instance.sizeBytes,
      'uploadedBy': instance.uploadedBy,
      'description': instance.description,
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
      'downloadUrl': instance.downloadUrl,
      'expiresAt': instance.expiresAt,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$SyncStatusEnumMap = {
  SyncStatus.local: 'local',
  SyncStatus.syncing: 'syncing',
  SyncStatus.synced: 'synced',
  SyncStatus.error: 'error',
};

_$PremiumFeaturesImpl _$$PremiumFeaturesImplFromJson(
        Map<String, dynamic> json) =>
    _$PremiumFeaturesImpl(
      syncEnabled: json['syncEnabled'] as bool? ?? false,
      uploadsEnabled: json['uploadsEnabled'] as bool? ?? false,
      storageUsedBytes: (json['storageUsedBytes'] as num?)?.toInt() ?? 0,
      storageLimitBytes:
          (json['storageLimitBytes'] as num?)?.toInt() ?? 104857600,
      subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
      subscriptionEnd: json['subscriptionEnd'] == null
          ? null
          : DateTime.parse(json['subscriptionEnd'] as String),
    );

Map<String, dynamic> _$$PremiumFeaturesImplToJson(
        _$PremiumFeaturesImpl instance) =>
    <String, dynamic>{
      'syncEnabled': instance.syncEnabled,
      'uploadsEnabled': instance.uploadsEnabled,
      'storageUsedBytes': instance.storageUsedBytes,
      'storageLimitBytes': instance.storageLimitBytes,
      'subscriptionTier': instance.subscriptionTier,
      'subscriptionEnd': instance.subscriptionEnd?.toIso8601String(),
    };

_$StorageUsageImpl _$$StorageUsageImplFromJson(Map<String, dynamic> json) =>
    _$StorageUsageImpl(
      usedBytes: (json['usedBytes'] as num).toInt(),
      limitBytes: (json['limitBytes'] as num).toInt(),
      usedPercent: (json['usedPercent'] as num).toDouble(),
      fileCount: (json['fileCount'] as num).toInt(),
      uploadsEnabled: json['uploadsEnabled'] as bool,
      usedMB: (json['usedMB'] as num).toDouble(),
      limitMB: (json['limitMB'] as num).toDouble(),
      remainingBytes: (json['remainingBytes'] as num).toInt(),
    );

Map<String, dynamic> _$$StorageUsageImplToJson(_$StorageUsageImpl instance) =>
    <String, dynamic>{
      'usedBytes': instance.usedBytes,
      'limitBytes': instance.limitBytes,
      'usedPercent': instance.usedPercent,
      'fileCount': instance.fileCount,
      'uploadsEnabled': instance.uploadsEnabled,
      'usedMB': instance.usedMB,
      'limitMB': instance.limitMB,
      'remainingBytes': instance.remainingBytes,
    };

_$UploadUrlResponseImpl _$$UploadUrlResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$UploadUrlResponseImpl(
      uploadUrl: json['uploadUrl'] as String,
      workSampleId: json['workSampleId'] as String,
      storageKey: json['storageKey'] as String,
      expiresAt: json['expiresAt'] as String,
    );

Map<String, dynamic> _$$UploadUrlResponseImplToJson(
        _$UploadUrlResponseImpl instance) =>
    <String, dynamic>{
      'uploadUrl': instance.uploadUrl,
      'workSampleId': instance.workSampleId,
      'storageKey': instance.storageKey,
      'expiresAt': instance.expiresAt,
    };
