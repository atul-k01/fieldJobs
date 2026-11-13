import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration and initialization wrapper for Supabase.
class SupabaseConfig {
  SupabaseConfig._();

  // Default placeholders: User can replace with their actual Supabase project keys
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'public-anon-key-placeholder',
  );

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Safely initialize Supabase. If credentials are placeholder or network fails,
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
      }
    } catch (_) {
      // In offline mode or with mock credentials, don't crash
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
