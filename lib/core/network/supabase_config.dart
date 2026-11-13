import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_log.dart';

/// Configuration and initialization wrapper for Supabase.
class SupabaseConfig {
  SupabaseConfig._();

  // Connected to live Supabase Backend
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://atadzziyjoadkwotlvms.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_O3qnTEJSOKKvGOB08-7cxg_8dvvlCyE',
  );

  static bool _isInitialized = false;
  static bool get isInitialized {
    if (_isInitialized) return true;
    try {
      final c = Supabase.instance.client;
      // ignore: unnecessary_null_comparison
      _isInitialized = (c != null);
      return _isInitialized;
    } catch (_) {
      return false;
    }
  }

  /// Safely initialize Supabase. If network fails or keys are invalid,
  /// the app operates gracefully in durable offline mode.
  static Future<void> init() async {
    try {
      if (supabaseUrl.isNotEmpty &&
          !supabaseUrl.contains('xyzcompany') &&
          supabaseAnonKey != 'public-anon-key-placeholder') {
        await Supabase.initialize(
          url: supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey,
        );
        _isInitialized = true;
        AppLog.i('SupabaseConfig', 'Connected to Supabase: $supabaseUrl');
      }
    } catch (e) {
      AppLog.w('SupabaseConfig', 'Supabase initialization failed, operating offline: $e');
      _isInitialized = false;
    }
  }

  static SupabaseClient? get client {
    if (_isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }
}
