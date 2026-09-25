// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_sample.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkSample _$WorkSampleFromJson(Map<String, dynamic> json) {
  return _WorkSample.fromJson(json);
}

/// @nodoc
mixin _$WorkSample {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get logEntryId => throw _privateConstructorUsedError;
  String? get groupId =>
      throw _privateConstructorUsedError; // Links to all logs in a multi-student group
  String get studentId => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  String? get localPath =>
      throw _privateConstructorUsedError; // Local file path (for offline storage)
  String? get storageKey =>
      throw _privateConstructorUsedError; // R2 object key (after sync)
  String get contentType => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  String get uploadedBy => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  SyncStatus get syncStatus => throw _privateConstructorUsedError;
  String? get downloadUrl =>
      throw _privateConstructorUsedError; // Pre-signed URL for viewing
  String? get expiresAt => throw _privateConstructorUsedError; // URL expiration
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkSampleCopyWith<WorkSample> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkSampleCopyWith<$Res> {
  factory $WorkSampleCopyWith(
          WorkSample value, $Res Function(WorkSample) then) =
      _$WorkSampleCopyWithImpl<$Res, WorkSample>;
  @useResult
  $Res call(
      {String id,
      String familyId,
      String logEntryId,
      String? groupId,
      String studentId,
      String fileName,
      String? localPath,
      String? storageKey,
      String contentType,
      int sizeBytes,
      String uploadedBy,
      String? description,
      SyncStatus syncStatus,
      String? downloadUrl,
      String? expiresAt,
      DateTime createdAt});
}

/// @nodoc
class _$WorkSampleCopyWithImpl<$Res, $Val extends WorkSample>
    implements $WorkSampleCopyWith<$Res> {
  _$WorkSampleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? logEntryId = null,
    Object? groupId = freezed,
    Object? studentId = null,
    Object? fileName = null,
    Object? localPath = freezed,
    Object? storageKey = freezed,
    Object? contentType = null,
    Object? sizeBytes = null,
    Object? uploadedBy = null,
    Object? description = freezed,
    Object? syncStatus = null,
    Object? downloadUrl = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      logEntryId: null == logEntryId
          ? _value.logEntryId
          : logEntryId // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      storageKey: freezed == storageKey
          ? _value.storageKey
          : storageKey // ignore: cast_nullable_to_non_nullable
              as String?,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      uploadedBy: null == uploadedBy
          ? _value.uploadedBy
          : uploadedBy // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      downloadUrl: freezed == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkSampleImplCopyWith<$Res>
    implements $WorkSampleCopyWith<$Res> {
  factory _$$WorkSampleImplCopyWith(
          _$WorkSampleImpl value, $Res Function(_$WorkSampleImpl) then) =
      __$$WorkSampleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String familyId,
      String logEntryId,
      String? groupId,
      String studentId,
      String fileName,
      String? localPath,
      String? storageKey,
      String contentType,
      int sizeBytes,
      String uploadedBy,
      String? description,
      SyncStatus syncStatus,
      String? downloadUrl,
      String? expiresAt,
      DateTime createdAt});
}

/// @nodoc
class __$$WorkSampleImplCopyWithImpl<$Res>
    extends _$WorkSampleCopyWithImpl<$Res, _$WorkSampleImpl>
    implements _$$WorkSampleImplCopyWith<$Res> {
  __$$WorkSampleImplCopyWithImpl(
      _$WorkSampleImpl _value, $Res Function(_$WorkSampleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? logEntryId = null,
    Object? groupId = freezed,
    Object? studentId = null,
    Object? fileName = null,
    Object? localPath = freezed,
    Object? storageKey = freezed,
    Object? contentType = null,
    Object? sizeBytes = null,
    Object? uploadedBy = null,
    Object? description = freezed,
    Object? syncStatus = null,
    Object? downloadUrl = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$WorkSampleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      familyId: null == familyId
          ? _value.familyId
          : familyId // ignore: cast_nullable_to_non_nullable
              as String,
      logEntryId: null == logEntryId
          ? _value.logEntryId
          : logEntryId // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      storageKey: freezed == storageKey
          ? _value.storageKey
          : storageKey // ignore: cast_nullable_to_non_nullable
              as String?,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      uploadedBy: null == uploadedBy
          ? _value.uploadedBy
          : uploadedBy // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      downloadUrl: freezed == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkSampleImpl implements _WorkSample {
  const _$WorkSampleImpl(
      {required this.id,
      required this.familyId,
      required this.logEntryId,
      this.groupId,
      required this.studentId,
      required this.fileName,
      this.localPath,
      this.storageKey,
      required this.contentType,
      required this.sizeBytes,
      required this.uploadedBy,
      this.description,
      this.syncStatus = SyncStatus.local,
      this.downloadUrl,
      this.expiresAt,
      required this.createdAt});

  factory _$WorkSampleImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkSampleImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String logEntryId;
  @override
  final String? groupId;
// Links to all logs in a multi-student group
  @override
  final String studentId;
  @override
  final String fileName;
  @override
  final String? localPath;
// Local file path (for offline storage)
  @override
  final String? storageKey;
// R2 object key (after sync)
  @override
  final String contentType;
  @override
  final int sizeBytes;
  @override
  final String uploadedBy;
  @override
  final String? description;
  @override
  @JsonKey()
  final SyncStatus syncStatus;
  @override
  final String? downloadUrl;
// Pre-signed URL for viewing
  @override
  final String? expiresAt;
// URL expiration
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'WorkSample(id: $id, familyId: $familyId, logEntryId: $logEntryId, groupId: $groupId, studentId: $studentId, fileName: $fileName, localPath: $localPath, storageKey: $storageKey, contentType: $contentType, sizeBytes: $sizeBytes, uploadedBy: $uploadedBy, description: $description, syncStatus: $syncStatus, downloadUrl: $downloadUrl, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkSampleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.logEntryId, logEntryId) ||
                other.logEntryId == logEntryId) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.storageKey, storageKey) ||
                other.storageKey == storageKey) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.uploadedBy, uploadedBy) ||
                other.uploadedBy == uploadedBy) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      familyId,
      logEntryId,
      groupId,
      studentId,
      fileName,
      localPath,
      storageKey,
      contentType,
      sizeBytes,
      uploadedBy,
      description,
      syncStatus,
      downloadUrl,
      expiresAt,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkSampleImplCopyWith<_$WorkSampleImpl> get copyWith =>
      __$$WorkSampleImplCopyWithImpl<_$WorkSampleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkSampleImplToJson(
      this,
    );
  }
}

abstract class _WorkSample implements WorkSample {
  const factory _WorkSample(
      {required final String id,
      required final String familyId,
      required final String logEntryId,
      final String? groupId,
      required final String studentId,
      required final String fileName,
      final String? localPath,
      final String? storageKey,
      required final String contentType,
      required final int sizeBytes,
      required final String uploadedBy,
      final String? description,
      final SyncStatus syncStatus,
      final String? downloadUrl,
      final String? expiresAt,
      required final DateTime createdAt}) = _$WorkSampleImpl;

  factory _WorkSample.fromJson(Map<String, dynamic> json) =
      _$WorkSampleImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String get logEntryId;
  @override
  String? get groupId;
  @override // Links to all logs in a multi-student group
  String get studentId;
  @override
  String get fileName;
  @override
  String? get localPath;
  @override // Local file path (for offline storage)
  String? get storageKey;
  @override // R2 object key (after sync)
  String get contentType;
  @override
  int get sizeBytes;
  @override
  String get uploadedBy;
  @override
  String? get description;
  @override
  SyncStatus get syncStatus;
  @override
  String? get downloadUrl;
  @override // Pre-signed URL for viewing
  String? get expiresAt;
  @override // URL expiration
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$WorkSampleImplCopyWith<_$WorkSampleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PremiumFeatures _$PremiumFeaturesFromJson(Map<String, dynamic> json) {
  return _PremiumFeatures.fromJson(json);
}

/// @nodoc
mixin _$PremiumFeatures {
  bool get syncEnabled => throw _privateConstructorUsedError;
  bool get uploadsEnabled => throw _privateConstructorUsedError;
  int get storageUsedBytes => throw _privateConstructorUsedError;
  int get storageLimitBytes =>
      throw _privateConstructorUsedError; // 100MB default
  String get subscriptionTier => throw _privateConstructorUsedError;
  DateTime? get subscriptionEnd => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PremiumFeaturesCopyWith<PremiumFeatures> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PremiumFeaturesCopyWith<$Res> {
  factory $PremiumFeaturesCopyWith(
          PremiumFeatures value, $Res Function(PremiumFeatures) then) =
      _$PremiumFeaturesCopyWithImpl<$Res, PremiumFeatures>;
  @useResult
  $Res call(
      {bool syncEnabled,
      bool uploadsEnabled,
      int storageUsedBytes,
      int storageLimitBytes,
      String subscriptionTier,
      DateTime? subscriptionEnd});
}

/// @nodoc
class _$PremiumFeaturesCopyWithImpl<$Res, $Val extends PremiumFeatures>
    implements $PremiumFeaturesCopyWith<$Res> {
  _$PremiumFeaturesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? syncEnabled = null,
    Object? uploadsEnabled = null,
    Object? storageUsedBytes = null,
    Object? storageLimitBytes = null,
    Object? subscriptionTier = null,
    Object? subscriptionEnd = freezed,
  }) {
    return _then(_value.copyWith(
      syncEnabled: null == syncEnabled
          ? _value.syncEnabled
          : syncEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      uploadsEnabled: null == uploadsEnabled
          ? _value.uploadsEnabled
          : uploadsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      storageUsedBytes: null == storageUsedBytes
          ? _value.storageUsedBytes
          : storageUsedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      storageLimitBytes: null == storageLimitBytes
          ? _value.storageLimitBytes
          : storageLimitBytes // ignore: cast_nullable_to_non_nullable
              as int,
      subscriptionTier: null == subscriptionTier
          ? _value.subscriptionTier
          : subscriptionTier // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionEnd: freezed == subscriptionEnd
          ? _value.subscriptionEnd
          : subscriptionEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PremiumFeaturesImplCopyWith<$Res>
    implements $PremiumFeaturesCopyWith<$Res> {
  factory _$$PremiumFeaturesImplCopyWith(_$PremiumFeaturesImpl value,
          $Res Function(_$PremiumFeaturesImpl) then) =
      __$$PremiumFeaturesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool syncEnabled,
      bool uploadsEnabled,
      int storageUsedBytes,
      int storageLimitBytes,
      String subscriptionTier,
      DateTime? subscriptionEnd});
}

/// @nodoc
class __$$PremiumFeaturesImplCopyWithImpl<$Res>
    extends _$PremiumFeaturesCopyWithImpl<$Res, _$PremiumFeaturesImpl>
    implements _$$PremiumFeaturesImplCopyWith<$Res> {
  __$$PremiumFeaturesImplCopyWithImpl(
      _$PremiumFeaturesImpl _value, $Res Function(_$PremiumFeaturesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? syncEnabled = null,
    Object? uploadsEnabled = null,
    Object? storageUsedBytes = null,
    Object? storageLimitBytes = null,
    Object? subscriptionTier = null,
    Object? subscriptionEnd = freezed,
  }) {
    return _then(_$PremiumFeaturesImpl(
      syncEnabled: null == syncEnabled
          ? _value.syncEnabled
          : syncEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      uploadsEnabled: null == uploadsEnabled
          ? _value.uploadsEnabled
          : uploadsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      storageUsedBytes: null == storageUsedBytes
          ? _value.storageUsedBytes
          : storageUsedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      storageLimitBytes: null == storageLimitBytes
          ? _value.storageLimitBytes
          : storageLimitBytes // ignore: cast_nullable_to_non_nullable
              as int,
      subscriptionTier: null == subscriptionTier
          ? _value.subscriptionTier
          : subscriptionTier // ignore: cast_nullable_to_non_nullable
              as String,
      subscriptionEnd: freezed == subscriptionEnd
          ? _value.subscriptionEnd
          : subscriptionEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PremiumFeaturesImpl implements _PremiumFeatures {
  const _$PremiumFeaturesImpl(
      {this.syncEnabled = false,
      this.uploadsEnabled = false,
      this.storageUsedBytes = 0,
      this.storageLimitBytes = 104857600,
      this.subscriptionTier = 'free',
      this.subscriptionEnd});

  factory _$PremiumFeaturesImpl.fromJson(Map<String, dynamic> json) =>
      _$$PremiumFeaturesImplFromJson(json);

  @override
  @JsonKey()
  final bool syncEnabled;
  @override
  @JsonKey()
  final bool uploadsEnabled;
  @override
  @JsonKey()
  final int storageUsedBytes;
  @override
  @JsonKey()
  final int storageLimitBytes;
// 100MB default
  @override
  @JsonKey()
  final String subscriptionTier;
  @override
  final DateTime? subscriptionEnd;

  @override
  String toString() {
    return 'PremiumFeatures(syncEnabled: $syncEnabled, uploadsEnabled: $uploadsEnabled, storageUsedBytes: $storageUsedBytes, storageLimitBytes: $storageLimitBytes, subscriptionTier: $subscriptionTier, subscriptionEnd: $subscriptionEnd)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PremiumFeaturesImpl &&
            (identical(other.syncEnabled, syncEnabled) ||
                other.syncEnabled == syncEnabled) &&
            (identical(other.uploadsEnabled, uploadsEnabled) ||
                other.uploadsEnabled == uploadsEnabled) &&
            (identical(other.storageUsedBytes, storageUsedBytes) ||
                other.storageUsedBytes == storageUsedBytes) &&
            (identical(other.storageLimitBytes, storageLimitBytes) ||
                other.storageLimitBytes == storageLimitBytes) &&
            (identical(other.subscriptionTier, subscriptionTier) ||
                other.subscriptionTier == subscriptionTier) &&
            (identical(other.subscriptionEnd, subscriptionEnd) ||
                other.subscriptionEnd == subscriptionEnd));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, syncEnabled, uploadsEnabled,
      storageUsedBytes, storageLimitBytes, subscriptionTier, subscriptionEnd);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PremiumFeaturesImplCopyWith<_$PremiumFeaturesImpl> get copyWith =>
      __$$PremiumFeaturesImplCopyWithImpl<_$PremiumFeaturesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PremiumFeaturesImplToJson(
      this,
    );
  }
}

abstract class _PremiumFeatures implements PremiumFeatures {
  const factory _PremiumFeatures(
      {final bool syncEnabled,
      final bool uploadsEnabled,
      final int storageUsedBytes,
      final int storageLimitBytes,
      final String subscriptionTier,
      final DateTime? subscriptionEnd}) = _$PremiumFeaturesImpl;

  factory _PremiumFeatures.fromJson(Map<String, dynamic> json) =
      _$PremiumFeaturesImpl.fromJson;

  @override
  bool get syncEnabled;
  @override
  bool get uploadsEnabled;
  @override
  int get storageUsedBytes;
  @override
  int get storageLimitBytes;
  @override // 100MB default
  String get subscriptionTier;
  @override
  DateTime? get subscriptionEnd;
  @override
  @JsonKey(ignore: true)
  _$$PremiumFeaturesImplCopyWith<_$PremiumFeaturesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StorageUsage _$StorageUsageFromJson(Map<String, dynamic> json) {
  return _StorageUsage.fromJson(json);
}

/// @nodoc
mixin _$StorageUsage {
  int get usedBytes => throw _privateConstructorUsedError;
  int get limitBytes => throw _privateConstructorUsedError;
  double get usedPercent => throw _privateConstructorUsedError;
  int get fileCount => throw _privateConstructorUsedError;
  bool get uploadsEnabled => throw _privateConstructorUsedError;
  double get usedMB => throw _privateConstructorUsedError;
  double get limitMB => throw _privateConstructorUsedError;
  int get remainingBytes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StorageUsageCopyWith<StorageUsage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StorageUsageCopyWith<$Res> {
  factory $StorageUsageCopyWith(
          StorageUsage value, $Res Function(StorageUsage) then) =
      _$StorageUsageCopyWithImpl<$Res, StorageUsage>;
  @useResult
  $Res call(
      {int usedBytes,
      int limitBytes,
      double usedPercent,
      int fileCount,
      bool uploadsEnabled,
      double usedMB,
      double limitMB,
      int remainingBytes});
}

/// @nodoc
class _$StorageUsageCopyWithImpl<$Res, $Val extends StorageUsage>
    implements $StorageUsageCopyWith<$Res> {
  _$StorageUsageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? usedBytes = null,
    Object? limitBytes = null,
    Object? usedPercent = null,
    Object? fileCount = null,
    Object? uploadsEnabled = null,
    Object? usedMB = null,
    Object? limitMB = null,
    Object? remainingBytes = null,
  }) {
    return _then(_value.copyWith(
      usedBytes: null == usedBytes
          ? _value.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      limitBytes: null == limitBytes
          ? _value.limitBytes
          : limitBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usedPercent: null == usedPercent
          ? _value.usedPercent
          : usedPercent // ignore: cast_nullable_to_non_nullable
              as double,
      fileCount: null == fileCount
          ? _value.fileCount
          : fileCount // ignore: cast_nullable_to_non_nullable
              as int,
      uploadsEnabled: null == uploadsEnabled
          ? _value.uploadsEnabled
          : uploadsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      usedMB: null == usedMB
          ? _value.usedMB
          : usedMB // ignore: cast_nullable_to_non_nullable
              as double,
      limitMB: null == limitMB
          ? _value.limitMB
          : limitMB // ignore: cast_nullable_to_non_nullable
              as double,
      remainingBytes: null == remainingBytes
          ? _value.remainingBytes
          : remainingBytes // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StorageUsageImplCopyWith<$Res>
    implements $StorageUsageCopyWith<$Res> {
  factory _$$StorageUsageImplCopyWith(
          _$StorageUsageImpl value, $Res Function(_$StorageUsageImpl) then) =
      __$$StorageUsageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int usedBytes,
      int limitBytes,
      double usedPercent,
      int fileCount,
      bool uploadsEnabled,
      double usedMB,
      double limitMB,
      int remainingBytes});
}

/// @nodoc
class __$$StorageUsageImplCopyWithImpl<$Res>
    extends _$StorageUsageCopyWithImpl<$Res, _$StorageUsageImpl>
    implements _$$StorageUsageImplCopyWith<$Res> {
  __$$StorageUsageImplCopyWithImpl(
      _$StorageUsageImpl _value, $Res Function(_$StorageUsageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? usedBytes = null,
    Object? limitBytes = null,
    Object? usedPercent = null,
    Object? fileCount = null,
    Object? uploadsEnabled = null,
    Object? usedMB = null,
    Object? limitMB = null,
    Object? remainingBytes = null,
  }) {
    return _then(_$StorageUsageImpl(
      usedBytes: null == usedBytes
          ? _value.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      limitBytes: null == limitBytes
          ? _value.limitBytes
          : limitBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usedPercent: null == usedPercent
          ? _value.usedPercent
          : usedPercent // ignore: cast_nullable_to_non_nullable
              as double,
      fileCount: null == fileCount
          ? _value.fileCount
          : fileCount // ignore: cast_nullable_to_non_nullable
              as int,
      uploadsEnabled: null == uploadsEnabled
          ? _value.uploadsEnabled
          : uploadsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      usedMB: null == usedMB
          ? _value.usedMB
          : usedMB // ignore: cast_nullable_to_non_nullable
              as double,
      limitMB: null == limitMB
          ? _value.limitMB
          : limitMB // ignore: cast_nullable_to_non_nullable
              as double,
      remainingBytes: null == remainingBytes
          ? _value.remainingBytes
          : remainingBytes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StorageUsageImpl implements _StorageUsage {
  const _$StorageUsageImpl(
      {required this.usedBytes,
      required this.limitBytes,
      required this.usedPercent,
      required this.fileCount,
      required this.uploadsEnabled,
      required this.usedMB,
      required this.limitMB,
      required this.remainingBytes});

  factory _$StorageUsageImpl.fromJson(Map<String, dynamic> json) =>
      _$$StorageUsageImplFromJson(json);

  @override
  final int usedBytes;
  @override
  final int limitBytes;
  @override
  final double usedPercent;
  @override
  final int fileCount;
  @override
  final bool uploadsEnabled;
  @override
  final double usedMB;
  @override
  final double limitMB;
  @override
  final int remainingBytes;

  @override
  String toString() {
    return 'StorageUsage(usedBytes: $usedBytes, limitBytes: $limitBytes, usedPercent: $usedPercent, fileCount: $fileCount, uploadsEnabled: $uploadsEnabled, usedMB: $usedMB, limitMB: $limitMB, remainingBytes: $remainingBytes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageUsageImpl &&
            (identical(other.usedBytes, usedBytes) ||
                other.usedBytes == usedBytes) &&
            (identical(other.limitBytes, limitBytes) ||
                other.limitBytes == limitBytes) &&
            (identical(other.usedPercent, usedPercent) ||
                other.usedPercent == usedPercent) &&
            (identical(other.fileCount, fileCount) ||
                other.fileCount == fileCount) &&
            (identical(other.uploadsEnabled, uploadsEnabled) ||
                other.uploadsEnabled == uploadsEnabled) &&
            (identical(other.usedMB, usedMB) || other.usedMB == usedMB) &&
            (identical(other.limitMB, limitMB) || other.limitMB == limitMB) &&
            (identical(other.remainingBytes, remainingBytes) ||
                other.remainingBytes == remainingBytes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, usedBytes, limitBytes,
      usedPercent, fileCount, uploadsEnabled, usedMB, limitMB, remainingBytes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StorageUsageImplCopyWith<_$StorageUsageImpl> get copyWith =>
      __$$StorageUsageImplCopyWithImpl<_$StorageUsageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StorageUsageImplToJson(
      this,
    );
  }
}

abstract class _StorageUsage implements StorageUsage {
  const factory _StorageUsage(
      {required final int usedBytes,
      required final int limitBytes,
      required final double usedPercent,
      required final int fileCount,
      required final bool uploadsEnabled,
      required final double usedMB,
      required final double limitMB,
      required final int remainingBytes}) = _$StorageUsageImpl;

  factory _StorageUsage.fromJson(Map<String, dynamic> json) =
      _$StorageUsageImpl.fromJson;

  @override
  int get usedBytes;
  @override
  int get limitBytes;
  @override
  double get usedPercent;
  @override
  int get fileCount;
  @override
  bool get uploadsEnabled;
  @override
  double get usedMB;
  @override
  double get limitMB;
  @override
  int get remainingBytes;
  @override
  @JsonKey(ignore: true)
  _$$StorageUsageImplCopyWith<_$StorageUsageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UploadUrlResponse _$UploadUrlResponseFromJson(Map<String, dynamic> json) {
  return _UploadUrlResponse.fromJson(json);
}

/// @nodoc
mixin _$UploadUrlResponse {
  String get uploadUrl => throw _privateConstructorUsedError;
  String get workSampleId => throw _privateConstructorUsedError;
  String get storageKey => throw _privateConstructorUsedError;
  String get expiresAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UploadUrlResponseCopyWith<UploadUrlResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UploadUrlResponseCopyWith<$Res> {
  factory $UploadUrlResponseCopyWith(
          UploadUrlResponse value, $Res Function(UploadUrlResponse) then) =
      _$UploadUrlResponseCopyWithImpl<$Res, UploadUrlResponse>;
  @useResult
  $Res call(
      {String uploadUrl,
      String workSampleId,
      String storageKey,
      String expiresAt});
}

/// @nodoc
class _$UploadUrlResponseCopyWithImpl<$Res, $Val extends UploadUrlResponse>
    implements $UploadUrlResponseCopyWith<$Res> {
  _$UploadUrlResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uploadUrl = null,
    Object? workSampleId = null,
    Object? storageKey = null,
    Object? expiresAt = null,
  }) {
    return _then(_value.copyWith(
      uploadUrl: null == uploadUrl
          ? _value.uploadUrl
          : uploadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      workSampleId: null == workSampleId
          ? _value.workSampleId
          : workSampleId // ignore: cast_nullable_to_non_nullable
              as String,
      storageKey: null == storageKey
          ? _value.storageKey
          : storageKey // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UploadUrlResponseImplCopyWith<$Res>
    implements $UploadUrlResponseCopyWith<$Res> {
  factory _$$UploadUrlResponseImplCopyWith(_$UploadUrlResponseImpl value,
          $Res Function(_$UploadUrlResponseImpl) then) =
      __$$UploadUrlResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uploadUrl,
      String workSampleId,
      String storageKey,
      String expiresAt});
}

/// @nodoc
class __$$UploadUrlResponseImplCopyWithImpl<$Res>
    extends _$UploadUrlResponseCopyWithImpl<$Res, _$UploadUrlResponseImpl>
    implements _$$UploadUrlResponseImplCopyWith<$Res> {
  __$$UploadUrlResponseImplCopyWithImpl(_$UploadUrlResponseImpl _value,
      $Res Function(_$UploadUrlResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uploadUrl = null,
    Object? workSampleId = null,
    Object? storageKey = null,
    Object? expiresAt = null,
  }) {
    return _then(_$UploadUrlResponseImpl(
      uploadUrl: null == uploadUrl
          ? _value.uploadUrl
          : uploadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      workSampleId: null == workSampleId
          ? _value.workSampleId
          : workSampleId // ignore: cast_nullable_to_non_nullable
              as String,
      storageKey: null == storageKey
          ? _value.storageKey
          : storageKey // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UploadUrlResponseImpl implements _UploadUrlResponse {
  const _$UploadUrlResponseImpl(
      {required this.uploadUrl,
      required this.workSampleId,
      required this.storageKey,
      required this.expiresAt});

  factory _$UploadUrlResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$UploadUrlResponseImplFromJson(json);

  @override
  final String uploadUrl;
  @override
  final String workSampleId;
  @override
  final String storageKey;
  @override
  final String expiresAt;

  @override
  String toString() {
    return 'UploadUrlResponse(uploadUrl: $uploadUrl, workSampleId: $workSampleId, storageKey: $storageKey, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UploadUrlResponseImpl &&
            (identical(other.uploadUrl, uploadUrl) ||
                other.uploadUrl == uploadUrl) &&
            (identical(other.workSampleId, workSampleId) ||
                other.workSampleId == workSampleId) &&
            (identical(other.storageKey, storageKey) ||
                other.storageKey == storageKey) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, uploadUrl, workSampleId, storageKey, expiresAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UploadUrlResponseImplCopyWith<_$UploadUrlResponseImpl> get copyWith =>
      __$$UploadUrlResponseImplCopyWithImpl<_$UploadUrlResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UploadUrlResponseImplToJson(
      this,
    );
  }
}

abstract class _UploadUrlResponse implements UploadUrlResponse {
  const factory _UploadUrlResponse(
      {required final String uploadUrl,
      required final String workSampleId,
      required final String storageKey,
      required final String expiresAt}) = _$UploadUrlResponseImpl;

  factory _UploadUrlResponse.fromJson(Map<String, dynamic> json) =
      _$UploadUrlResponseImpl.fromJson;

  @override
  String get uploadUrl;
  @override
  String get workSampleId;
  @override
  String get storageKey;
  @override
  String get expiresAt;
  @override
  @JsonKey(ignore: true)
  _$$UploadUrlResponseImplCopyWith<_$UploadUrlResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
