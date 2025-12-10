import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

/// Service for monitoring network connectivity status
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  
  ConnectivityService._();
  
  final Connectivity _connectivity = Connectivity();
  
  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => _isConnected(results));
  
  /// Current connectivity status (cached)
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  /// Initialize the service and start monitoring
  Future<void> init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    Log.connectivity.d('Initial status: ${_isOnline ? 'online' : 'offline'}');
    
    // Listen for changes
    _connectivity.onConnectivityChanged.listen((results) {
      final newStatus = _isConnected(results);
      if (newStatus != _isOnline) {
        _isOnline = newStatus;
        Log.connectivity.d('Status changed: ${_isOnline ? 'online' : 'offline'}');
      }
    });
  }
  
  /// Check connectivity and return whether we're online
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }
  
  /// Determine if any of the connectivity results indicate a connection
  bool _isConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    
    // We're online if we have any connection other than 'none'
    return results.any((result) => 
      result != ConnectivityResult.none
    );
  }
}
