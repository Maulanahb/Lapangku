import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/services/firebase/auth_service.dart';

// Provider untuk service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// State untuk auth
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
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

// Notifier (Controller)
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

    Future<void> login(String email, String password) async {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final user = await _service.login(email, password);
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
        final user = await _service.register(
          email: email,
          password: password,
          nama: name,
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
    await _service.logout();
    state = const AuthState();
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.sendPasswordReset(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseAuthError(e),
      );
    }
  }
}

// Provider utama yang dipakai UI
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});

// Provider untuk cek auth state (login/logout)
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});
