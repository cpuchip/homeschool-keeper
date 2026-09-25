import 'dart:async';
import 'connectivity_service.dart';
import 'sync_service.dart';
import '../utils/logger.dart';

/// Service for automatically syncing data changes when online
/// 
/// Features:
/// - Debounced sync: Waits for a quiet period before syncing
/// - Queue management: Coalesces multiple rapid changes
/// - Connectivity-aware: Only syncs when online
/// - Retry on reconnect: Pushes pending changes when coming back online
class AutoSyncService {
  static AutoSyncService? _instance;
  
  final SyncService _syncService;
  final ConnectivityService _connectivity;
  
  /// Debounce duration before triggering sync
  final Duration debounceDelay;
  
  /// Timer for debounced sync
  Timer? _debounceTimer;
  
  /// Whether a sync is pending
  bool _syncPending = false;
  
  /// Callback when sync completes
  void Function(SyncResult)? onSyncComplete;
  
  AutoSyncService._({
    required SyncService syncService,
    ConnectivityService? connectivity,
    this.debounceDelay = const Duration(seconds: 2),
  })  : _syncService = syncService,
        _connectivity = connectivity ?? ConnectivityService.instance;
  
  /// Get or create the singleton instance
  static AutoSyncService get instance {
    if (_instance == null) {
      throw StateError('AutoSyncService not initialized. Call AutoSyncService.init() first.');
    }
    return _instance!;
  }
  
  /// Initialize the auto-sync service
  static Future<AutoSyncService> init({
    required SyncService syncService,
    ConnectivityService? connectivity,
    Duration debounceDelay = const Duration(seconds: 2),
  }) async {
    _instance = AutoSyncService._(
      syncService: syncService,
      connectivity: connectivity,
      debounceDelay: debounceDelay,
    );
    
    // Listen for connectivity changes to sync when coming online
    _instance!._listenForConnectivity();
    
    Log.autoSync.d('Initialized with ${debounceDelay.inSeconds}s debounce');
    return _instance!;
  }
  
  /// Notify that data has changed and should be synced
  /// 
  /// This is debounced - multiple calls within [debounceDelay] will be coalesced
  void notifyDataChanged() {
    _syncPending = true;
    
    // Cancel existing timer
    _debounceTimer?.cancel();
    
    // Start new debounce timer
    _debounceTimer = Timer(debounceDelay, _performSyncIfOnline);
    
    Log.autoSync.d('Data change queued (debounce ${debounceDelay.inSeconds}s)');
  }
  
  /// Immediately push changes (skip debounce)
  Future<SyncResult> pushNow() async {
    _debounceTimer?.cancel();
    _syncPending = false;
    
    if (!_connectivity.isOnline) {
      Log.autoSync.d('Offline - changes saved locally');
      return SyncResult.error('Offline');
    }
    
    Log.autoSync.d('Pushing changes immediately...');
    final result = await _syncService.pushChanges();
    onSyncComplete?.call(result);
    return result;
  }
  
  /// Perform sync if online
  Future<void> _performSyncIfOnline() async {
    if (!_syncPending) return;
    
    if (!_connectivity.isOnline) {
      Log.autoSync.d('Offline - will sync when connection returns');
      return;
    }
    
    _syncPending = false;
    Log.autoSync.d('Debounce complete, pushing changes...');
    
    final result = await _syncService.pushChanges();
    
    if (result.success) {
      Log.autoSync.d('Push complete: ${result.totalPushed} items');
    } else {
      Log.autoSync.w('Push failed: ${result.error}');
    }
    
    onSyncComplete?.call(result);
  }
  
  /// Listen for connectivity changes
  void _listenForConnectivity() {
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline && _syncService.getPendingChangesCount() > 0) {
        Log.autoSync.d('Back online with pending changes, syncing...');
        // Give the connection a moment to stabilize
        Future.delayed(const Duration(seconds: 1), () {
          _syncService.performFullSync();
        });
      }
    });
  }
  
  /// Check if there are pending changes
  bool get hasPendingChanges => _syncService.getPendingChangesCount() > 0;
  
  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
  }
}
