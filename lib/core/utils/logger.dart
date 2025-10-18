import 'package:flutter/foundation.dart';

/// Simple logger utility for the app
class Logger {
  Logger._();

  /// Log info messages
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO] $message');
    }
  }

  /// Log error messages
  static void error(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR] $message');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log warning messages
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARNING] $message');
    }
  }

  /// Log debug messages
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🐛 [DEBUG] $message');
    }
  }

  /// Log success messages
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ [SUCCESS] $message');
    }
  }
}
