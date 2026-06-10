import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/services/firebase/auth_service.dart';

// Provider utama untuk AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Struktur data (State) untuk menyimpan status otentikasi pengguna
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
  if (msg.contains('invalid-credential')) return 'Email atau password salah. Jika akun ini dibuat via Google, gunakan tombol "Lanjutkan dengan Google".';
  if (msg.contains('account-exists-with-different-credential')) return 'Akun dengan email ini sudah ada. Silakan login dengan metode yang sesuai.';
  if (msg.contains('email-already-in-use')) return 'Email sudah digunakan.';
  if (msg.contains('weak-password')) return 'Password minimal 6 karakter.';
  if (msg.contains('invalid-email')) return 'Format email tidak valid.';
  if (msg.contains('network-request-failed')) return 'Cek koneksi internet.';
  if (msg.contains('too-many-requests')) return 'Terlalu banyak percobaan. Coba lagi nanti.';
  return 'Terjadi kesalahan. Silakan coba lagi.';
}

// Controller utama untuk mengatur proses masuk, daftar, dan kelola akun
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

    // Proses masuk (login) dengan email dan password
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

    // Proses masuk otomatis menggunakan akun Google
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

    // Mendaftarkan akun baru
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

  // Keluar dari akun (logout)
  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }

  // Mengubah status loading manual saat ada proses berjalan
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  // Mengirim link reset password ke email pengguna
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

  // Memperbarui data profil pengguna
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

  // Memperbarui foto profil (avatar) pengguna
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



  // Menyimpan pengaturan preferensi notifikasi pengguna
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

  // Mengirimkan email verifikasi untuk akun baru
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

  // Mengirim kode OTP ke nomor telepon untuk verifikasi (SMS)
  Future<void> sendPhoneVerificationOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(Exception) onError,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.sendPhoneVerificationOTP(
        phoneNumber: phoneNumber,
        codeSent: (verificationId) {
          state = state.copyWith(isLoading: false);
          onCodeSent(verificationId);
        },
        verificationFailed: (e) {
          state = state.copyWith(isLoading: false, errorMessage: e.toString());
          onError(e);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      onError(Exception(e.toString()));
    }
  }

  // Memverifikasi kode OTP yang dimasukkan
  Future<void> verifyPhoneOTP(String verificationId, String smsCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.verifyPhoneOTP(verificationId, smsCode);
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Mengganti password lama dengan password baru
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

  void syncUser(UserModel? user) {
    state = state.copyWith(
      user: user,
      clearUser: user == null,
      clearError: true,
    );
  }
}

// Provider untuk memanggil AuthNotifier di UI
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(service);

  // Sync auth state from stream provider to keep it updated on app startup and state changes
  ref.listen<AsyncValue<UserModel?>>(authStateProvider, (previous, next) {
    next.when(
      data: (user) => notifier.syncUser(user),
      error: (e, s) {},
      loading: () {},
    );
  }, fireImmediately: true);

  return notifier;
});

// Stream untuk selalu memantau status login (apakah sedang login atau tidak)
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

/// Provider untuk mendapatkan UID pengguna saat ini secara reaktif
final currentUidProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
});
