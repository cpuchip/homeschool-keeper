import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'constants.dart';

/// TelemetryService handles anonymous usage tracking.
/// 
/// Privacy-first design:
/// - Uses random install ID (not tied to any identity)
/// - No PII collected
/// - User can opt out in settings
/// - Data is separate from user accounts
class TelemetryService {
  static TelemetryService? _instance;
  static TelemetryService get instance => _instance ??= TelemetryService._();
  
  TelemetryService._();

  static const _boxName = 'telemetry';
  static const _installIdKey = 'install_id';
  static const _enabledKey = 'enabled';
  static const _firstLaunchKey = 'first_launch';

  Box<dynamic>? _box;
  String? _installId;
  String? _appVersion;
  String? _platform;
  bool _enabled = true;
  bool _initialized = false;
  late Dio _dio;
  
  final List<Map<String, dynamic>> _pendingEvents = [];
  Timer? _flushTimer;
  
  /// Initialize the telemetry service
  Future<void> init() async {
    if (_initialized) return;
    
    // Initialize Hive box
    _box = await Hive.openBox(_boxName);
    
    // Initialize Dio for telemetry (no auth needed)
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl.replaceAll('/api/v1', ''),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),);
    
    // Get or create install ID
    _installId = _box!.get(_installIdKey);
    if (_installId == null) {
      _installId = const Uuid().v4();
      await _box!.put(_installIdKey, _installId);
    }
    
    // Check if enabled
    _enabled = _box!.get(_enabledKey, defaultValue: true);
    
    // Get app version
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (_) {
      _appVersion = 'unknown';
    }
    
    // Get platform
    _platform = _getPlatform();
    
    _initialized = true;
    
    // Track first launch if needed
    final isFirstLaunch = _box!.get(_firstLaunchKey, defaultValue: true);
    if (isFirstLaunch) {
      await _box!.put(_firstLaunchKey, false);
      trackEvent(TelemetryEvents.appInstall);
    }
    
    // Start flush timer (every 30 seconds)
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
    
    // Track session start
    trackEvent(TelemetryEvents.sessionStart);
  }
  
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
  
  /// Check if telemetry is enabled
  bool get isEnabled => _enabled;
  
  /// Get install ID (for debugging)
  String? get installId => _installId;
  
  /// Enable or disable telemetry
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _box?.put(_enabledKey, enabled);
    
    // Track the opt-in/opt-out event (this one still goes through)
    if (enabled) {
      _trackEventInternal(TelemetryEvents.telemetryOptIn, null);
    } else {
      _trackEventInternal(TelemetryEvents.telemetryOptOut, null);
    }
    await flush();
  }
  
  /// Track an event
  void trackEvent(String event, [Map<String, dynamic>? data]) {
    if (!_enabled || !_initialized) return;
    _trackEventInternal(event, data);
  }
  
  void _trackEventInternal(String event, Map<String, dynamic>? data) {
    final eventData = <String, dynamic>{
      'installId': _installId,
      'appVersion': _appVersion,
      'platform': _platform,
      'event': event,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    
    if (data != null && data.isNotEmpty) {
      eventData['data'] = data;
    }
    
    _pendingEvents.add(eventData);
    
    // If we have 10+ events, flush immediately
    if (_pendingEvents.length >= 10) {
      flush();
    }
  }
  
  /// Track a screen view
  void trackScreen(String screenName) {
    trackEvent(TelemetryEvents.screenView, {'screen': screenName});
  }
  
  /// Flush pending events to server
  Future<void> flush() async {
    if (_pendingEvents.isEmpty) return;
    
    // Take a copy and clear
    final events = List<Map<String, dynamic>>.from(_pendingEvents);
    _pendingEvents.clear();
    
    try {
      await _dio.post('/api/v1/telemetry/batch', data: {'events': events});
      debugPrint('Telemetry: Sent ${events.length} events');
    } catch (e) {
      // Failed - add back for retry (but limit to 100)
      if (_pendingEvents.length < 100) {
        _pendingEvents.addAll(events);
      }
      debugPrint('Telemetry flush failed: $e');
    }
  }
  
  /// Called when app is closing
  Future<void> dispose() async {
    _flushTimer?.cancel();
    await flush();
  }
}

/// Standard telemetry event names
class TelemetryEvents {
  // Tier 1 - Essential
  static const appInstall = 'app_install';
  static const sessionStart = 'session_start';
  static const sessionEnd = 'session_end';
  
  // Tier 2 - Usage
  static const screenView = 'screen_view';
  static const onboardingStarted = 'onboarding_started';
  static const onboardingCompleted = 'onboarding_completed';
  static const accountCreated = 'account_created';
  static const syncEnabled = 'sync_enabled';
  static const logCreated = 'log_created';
  static const logEdited = 'log_edited';
  static const studentAdded = 'student_added';
  static const subjectAdded = 'subject_added';
  static const workSampleAdded = 'work_sample_added';
  static const exportGenerated = 'export_generated';
  static const telemetryOptOut = 'telemetry_opt_out';
  static const telemetryOptIn = 'telemetry_opt_in';
}
