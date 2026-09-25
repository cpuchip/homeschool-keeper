import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync/connectivity_service.dart';
import '../core/sync/auto_sync_service.dart';
import 'sync_provider.dart';

/// Connectivity state
class ConnectivityState {
  final bool isOnline;
  final DateTime? lastOnlineAt;
  
  const ConnectivityState({
    this.isOnline = true,
    this.lastOnlineAt,
  });
  
  ConnectivityState copyWith({
    bool? isOnline,
    DateTime? lastOnlineAt,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
    );
  }
}

/// Notifier for connectivity state
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;
  
  ConnectivityNotifier(this._service) : super(const ConnectivityState()) {
    _init();
  }
  
  Future<void> _init() async {
    // Get initial state
    final isOnline = await _service.checkConnectivity();
    state = ConnectivityState(
      isOnline: isOnline,
      lastOnlineAt: isOnline ? DateTime.now() : null,
    );
    
    // Listen for changes
    _subscription = _service.onConnectivityChanged.listen((isOnline) {
      state = state.copyWith(
        isOnline: isOnline,
        lastOnlineAt: isOnline ? DateTime.now() : state.lastOnlineAt,
      );
    });
  }
  
  /// Manual check
  Future<bool> checkConnectivity() async {
    final isOnline = await _service.checkConnectivity();
    state = state.copyWith(
      isOnline: isOnline,
      lastOnlineAt: isOnline ? DateTime.now() : state.lastOnlineAt,
    );
    return isOnline;
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider for connectivity state
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return ConnectivityNotifier(service);
});

/// Provider for auto-sync service (initialized lazily with sync service)
final autoSyncServiceProvider = Provider<AutoSyncService?>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  
  // Initialize the singleton if not done yet
  try {
    return AutoSyncService.instance;
  } catch (_) {
    // Not initialized yet, do it now
    AutoSyncService.init(syncService: syncService);
    return AutoSyncService.instance;
  }
});

/// Helper to notify auto-sync of data changes
void notifyDataChanged(WidgetRef ref) {
  final autoSync = ref.read(autoSyncServiceProvider);
  autoSync?.notifyDataChanged();
}
