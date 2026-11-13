import 'package:flutter/foundation.dart';

/// Centralized logger utility for FieldJobs.
/// Logs are printed ONLY in debug mode (`kDebugMode`) and completely silenced in release builds.
class AppLog {
  AppLog._();

  static const String _appTag = 'FieldJobs';

  /// Debug log: detailed operational info
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$_appTag][$tag][DEBUG] $message');
    }
  }

  /// Info log: high-level state transitions and milestones
  static void i(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$_appTag][$tag][INFO] $message');
    }
  }

  /// Warning log: non-fatal issues or offline queue notices
  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$_appTag][$tag][WARN] ⚠️ $message');
    }
  }

  /// Error log: exceptions and conflict anomalies
  static void e(
    String tag,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      debugPrint('[$_appTag][$tag][ERROR] ❌ $message');
      if (error != null) {
        debugPrint('[$_appTag][$tag][ERROR_DETAIL] $error');
      }
      if (stackTrace != null) {
        debugPrint('[$_appTag][$tag][STACKTRACE] $stackTrace');
      }
    }
  }
}
