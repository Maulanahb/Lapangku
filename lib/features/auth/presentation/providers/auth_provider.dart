import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Provider untuk repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// State untuk auth
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
String _parseAuthError(Object e) {
  final msg = e.toString();
  if (msg.contains('user-not-found')) return 'Email tidak terdaftar.';
  if (msg.contains('wrong-password')) return 'Password salah.';
  if (msg.contains('email-already-in-use')) return 'Email sudah digunakan.';
  if (msg.contains('weak-password')) return 'Password minimal 6 karakter.';
  if (msg.contains('invalid-email')) return 'Format email tidak valid.';
  if (msg.contains('network-request-failed')) return 'Cek koneksi internet.';
  if (msg.contains('too-many-requests')) return 'Terlalu banyak percobaan. Coba lagi nanti.';
  return 'Terjadi kesalahan. Silakan coba lagi.';
}
// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

    Future<void> login(String email, String password) async {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final user = await _repository.login(email, password);
        state = state.copyWith(user: user, isLoading: false, clearError: true);
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _parseAuthError(e), 
        );
      }
    }

    Future<void> register({
      required String email,
      required String password,
      required String name,
      required String phone,
      required String role,
    }) async {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final user = await _repository.register(
          email: email,
          password: password,
          name: name,
          phone: phone,
          role: role,
        );
        state = state.copyWith(user: user, isLoading: false, clearError: true);
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _parseAuthError(e),
        );
      }
    }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.sendPasswordReset(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// Provider utama yang dipakai UI
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// Provider untuk cek auth state (login/logout)
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});