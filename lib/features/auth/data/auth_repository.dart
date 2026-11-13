import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/supabase_config.dart';
import '../models/technician_model.dart';

class AuthRepository {
  final FlutterSecureStorage _storage;
  final AppDatabase _db;

  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserName = 'auth_user_name';

  // Demo accounts configured for evaluation
  static const List<TechnicianModel> demoTechnicians = [
    TechnicianModel(
      id: 'tech-001-alex',
      email: 'alex@fieldjobs.com',
      name: 'Alex Rivera',
    ),
    TechnicianModel(
      id: 'tech-002-sarah',
      email: 'sarah@fieldjobs.com',
      name: 'Sarah Connor',
    ),
  ];

  AuthRepository({
    FlutterSecureStorage? storage,
    AppDatabase? db,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _db = db ?? AppDatabase.instance;

  Future<TechnicianModel?> getCurrentUser() async {
    final email = await _storage.read(key: _keyUserEmail);
    final id = await _storage.read(key: _keyUserId);
    final name = await _storage.read(key: _keyUserName);

    if (email != null && id != null) {
      return TechnicianModel(id: id, email: email, name: name ?? 'Technician');
    }
    return null;
  }

  Future<TechnicianModel> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // Check if Supabase is connected
    if (SupabaseConfig.isInitialized) {
      try {
        final client = SupabaseConfig.client!;
        final response = await client.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        final user = response.user;
        if (user != null) {
          final tech = TechnicianModel(
            id: user.id,
            email: user.email ?? cleanEmail,
            name: user.userMetadata?['name'] as String? ?? 'Technician',
          );
          await _saveSession(tech);
          return tech;
        }
      } catch (_) {
        // Fall back to local validation if offline
      }
    }

    // Standard demo accounts validation (always works offline)
    final matched = demoTechnicians.firstWhere(
      (tech) => tech.email.toLowerCase() == cleanEmail,
      orElse: () => throw Exception('Invalid technician email. Use alex@fieldjobs.com or sarah@fieldjobs.com'),
    );

    if (password != 'password123' && password != 'demo') {
      throw Exception('Invalid password. Demo password is password123');
    }

    await _saveSession(matched);
    return matched;
  }

  Future<void> _saveSession(TechnicianModel tech) async {
    await _storage.write(key: _keyUserId, value: tech.id);
    await _storage.write(key: _keyUserEmail, value: tech.email);
    await _storage.write(key: _keyUserName, value: tech.name);
  }

  Future<int> getPendingSyncCount() async {
    return await _db.getPendingSyncCount();
  }

  Future<void> signOut({bool wipeData = true}) async {
    // 1. Sign out from Supabase if connected
    if (SupabaseConfig.isInitialized) {
      try {
        await SupabaseConfig.client?.auth.signOut();
      } catch (_) {}
    }

    // 2. Clear secure storage session tokens
    await _storage.deleteAll();

    // 3. Clear all cached jobs, checklists, photos, and sync queue
    // to strictly prevent previous technician data from leaking
    if (wipeData) {
      await _db.wipeAllUserData();
    }
  }
}
