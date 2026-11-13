import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/utils/app_log.dart';
import '../models/technician_model.dart';

class AuthRepository extends BaseRepository {
  final FlutterSecureStorage _storage;
  final AppDatabase _db;

  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserName = 'auth_user_name';

  // Demo accounts configured for evaluation (Atul Kumar & Nitin Sharma)
  static const List<TechnicianModel> demoTechnicians = [
    TechnicianModel(
      id: 'tech-001-atul',
      email: 'atul@fieldjobs.com',
      name: 'Atul Kumar',
    ),
    TechnicianModel(
      id: 'tech-002-nitin',
      email: 'nitin@fieldjobs.com',
      name: 'Nitin Sharma',
    ),
  ];

  AuthRepository({
    FlutterSecureStorage? storage,
    AppDatabase? db,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _db = db ?? AppDatabase.instance,
        super(tag: 'AuthRepository');

  Future<TechnicianModel?> getCurrentUser() {
    return safeCall(
      () async {
        final email = await _storage.read(key: _keyUserEmail);
        final id = await _storage.read(key: _keyUserId);
        final name = await _storage.read(key: _keyUserName);

        if (email != null && id != null) {
          return TechnicianModel(id: id, email: email, name: name ?? 'Technician');
        }
        return null;
      },
      operation: 'getCurrentUser',
    );
  }

  Future<TechnicianModel> signIn(String email, String password) {
    return safeCall(
      () async {
        final cleanEmail = email.trim().toLowerCase();
        AppLog.d('AuthRepository', 'Attempting sign in for: $cleanEmail');

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
              AppLog.i('AuthRepository', 'Signed in successfully via Supabase: ${tech.email}');
              return tech;
            }
          } catch (e) {
            AppLog.w('AuthRepository', 'Supabase sign-in failed, falling back to local demo: $e');
          }
        }

        // Standard demo accounts validation (always works offline)
        final matched = demoTechnicians.firstWhere(
          (tech) => tech.email.toLowerCase() == cleanEmail,
          orElse: () {
            AppLog.e('AuthRepository', 'Invalid email entered: $cleanEmail');
            throw AuthException(message: 'Invalid technician email. Use atul@fieldjobs.com or nitin@fieldjobs.com');
          },
        );

        if (password != 'password123' && password != 'demo') {
          AppLog.e('AuthRepository', 'Invalid password entered for: $cleanEmail');
          throw AuthException(message: 'Invalid password. Demo password is password123');
        }

        await _saveSession(matched);
        AppLog.i('AuthRepository', 'Signed in successfully via demo credentials: ${matched.email}');
        return matched;
      },
      operation: 'signIn($email)',
    );
  }

  Future<void> _saveSession(TechnicianModel tech) async {
    await _storage.write(key: _keyUserId, value: tech.id);
    await _storage.write(key: _keyUserEmail, value: tech.email);
    await _storage.write(key: _keyUserName, value: tech.name);
  }

  Future<int> getPendingSyncCount() {
    return safeCall(
      () => _db.getPendingSyncCount(),
      operation: 'getPendingSyncCount',
    );
  }

  Future<void> signOut({bool wipeData = true}) {
    return safeCall(
      () async {
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
      },
      operation: 'signOut',
    );
  }
}
