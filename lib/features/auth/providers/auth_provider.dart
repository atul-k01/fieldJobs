import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/technician_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final TechnicianModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    TechnicianModel? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState(isLoading: true)) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AuthState(user: user, isLoading: false);
    } catch (_) {
      state = const AuthState(user: null, isLoading: false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signIn(email, password);
      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<int> getPendingSyncCount() async {
    return await _repository.getPendingSyncCount();
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut(wipeData: true);
    state = const AuthState(user: null, isLoading: false);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
