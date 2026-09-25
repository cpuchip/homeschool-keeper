import 'package:flutter/foundation.dart';

/// Simple logger utility that only logs in debug mode.
/// This avoids Android lint warnings about print statements in release builds.
class AppLogger {
  final String _tag;

  const AppLogger(this._tag);

  /// Log a debug message (only in debug mode)
  void d(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] $message');
    }
  }

  /// Log an info message
  void i(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] $message');
    }
  }

  /// Log a warning message
  void w(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] ⚠️ $message');
    }
  }

  /// Log an error message
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$_tag] ❌ $message');
      if (error != null) {
        debugPrint('[$_tag] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$_tag] Stack: $stackTrace');
      }
    }
  }
}

// Pre-defined loggers for common modules
class Log {
  static const api = AppLogger('API');
  static const auth = AppLogger('Auth');
  static const sync = AppLogger('Sync');
  static const autoSync = AppLogger('AutoSync');
  static const connectivity = AppLogger('Connectivity');
  static const storage = AppLogger('TokenStorage');
  static const backup = AppLogger('Backup');
}
