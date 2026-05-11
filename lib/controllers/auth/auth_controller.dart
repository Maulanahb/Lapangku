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

    Future<void> loginWithGoogle() async {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final user = await _service.signInWithGoogle();
        state = state.copyWith(user: user, isLoading: false, clearError: true);
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().contains('dibatalkan') 
              ? 'Login dibatalkan.' 
              : e.toString(), // Menampilkan pesan error asli untuk debugging
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.sendPasswordReset(email);
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseAuthError(e),
      );
    }
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? gender,
    String? city,
    String? address,
    String? birthday,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.updateProfile(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        gender: gender,
        city: city,
        address: address,
        birthday: birthday,
      );
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengupdate profil: $e',
      );
      rethrow;
    }
  }

  Future<void> updateAvatar(String uid, String? url) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.updateAvatar(uid, url);
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengupdate foto profil: $e',
      );
      rethrow;
    }
  }

  Future<void> updateTwoFactor(String uid, bool enabled) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.updateTwoFactor(uid, enabled);
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengupdate verifikasi 2 langkah: $e',
      );
      rethrow;
    }
  }

  Future<void> updateNotificationSettings(
      String uid, Map<String, bool> settings) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.updateNotificationSettings(uid, settings);
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengupdate pengaturan notifikasi: $e',
      );
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.sendEmailVerification();
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengirim email verifikasi: $e',
      );
      rethrow;
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.changePassword(oldPassword: oldPassword, newPassword: newPassword);
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
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
