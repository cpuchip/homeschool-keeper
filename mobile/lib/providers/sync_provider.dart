import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/sync/sync_service.dart';

/// Sync state for UI
class SyncState {
  final SyncStatus status;
  final String? error;
  final DateTime? lastSyncTime;
  final int pendingChanges;
  final SyncResult? lastResult;

  const SyncState({
    this.status = SyncStatus.idle,
    this.error,
    this.lastSyncTime,
    this.pendingChanges = 0,
    this.lastResult,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? error,
    DateTime? lastSyncTime,
    int? pendingChanges,
    SyncResult? lastResult,
  }) {
    return SyncState(
      status: status ?? this.status,
      error: error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      lastResult: lastResult ?? this.lastResult,
    );
  }

  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasError => status == SyncStatus.error && error != null;
  bool get hasPendingChanges => pendingChanges > 0;

  String get statusText {
    switch (status) {
      case SyncStatus.idle:
        return pendingChanges > 0 
            ? '$pendingChanges changes pending'
            : 'Up to date';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.error:
        return 'Sync failed';
    }
  }

  String? get lastSyncText {
    if (lastSyncTime == null) return 'Never synced';
    
    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${lastSyncTime!.month}/${lastSyncTime!.day}/${lastSyncTime!.year}';
  }
}

/// Sync state notifier
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(const SyncState()) {
    _loadInitialState();
  }

  void _loadInitialState() {
    state = state.copyWith(
      lastSyncTime: _syncService.getLastSyncTime(),
      pendingChanges: _syncService.getPendingChangesCount(),
    );
  }

  /// Perform a full sync (push and pull)
  /// Set [incremental] to false to do a full sync ignoring last sync time
  Future<SyncResult> performFullSync({bool incremental = true}) async {
    if (state.isSyncing) {
      return SyncResult.error('Sync already in progress');
    }

    state = state.copyWith(status: SyncStatus.syncing, error: null);

    final result = await _syncService.performFullSync(incremental: incremental);

    if (result.success) {
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: result.syncedAt,
        pendingChanges: _syncService.getPendingChangesCount(),
        lastResult: result,
        error: null,
      );
    } else {
      state = state.copyWith(
        status: SyncStatus.error,
        error: result.error,
        pendingChanges: _syncService.getPendingChangesCount(),
        lastResult: result,
      );
    }

    return result;
  }

  /// Push local changes only
  Future<SyncResult> pushChanges() async {
    if (state.isSyncing) {
      return SyncResult.error('Sync already in progress');
    }

    state = state.copyWith(status: SyncStatus.syncing, error: null);

    final result = await _syncService.pushChanges();

    state = state.copyWith(
      status: result.success ? SyncStatus.success : SyncStatus.error,
      error: result.error,
      pendingChanges: _syncService.getPendingChangesCount(),
      lastResult: result,
    );

    return result;
  }

  /// Pull data from server only
  Future<SyncResult> pullData() async {
    if (state.isSyncing) {
      return SyncResult.error('Sync already in progress');
    }

    state = state.copyWith(status: SyncStatus.syncing, error: null);

    final result = await _syncService.pullData();

    if (result.success) {
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: result.syncedAt,
        pendingChanges: _syncService.getPendingChangesCount(),
        lastResult: result,
        error: null,
      );
    } else {
      state = state.copyWith(
        status: SyncStatus.error,
        error: result.error,
        pendingChanges: _syncService.getPendingChangesCount(),
        lastResult: result,
      );
    }

    return result;
  }

  /// Refresh pending changes count
  void refreshPendingCount() {
    state = state.copyWith(
      pendingChanges: _syncService.getPendingChangesCount(),
    );
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(status: SyncStatus.idle, error: null);
  }
}

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SyncService(apiClient);
});

/// Provider for sync state
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService);
});
