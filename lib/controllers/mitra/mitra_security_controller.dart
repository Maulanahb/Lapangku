import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_device_model.dart';
import 'package:lapangku/models/mitra/mitra_security_log_model.dart';
import 'package:lapangku/core/services/firestore_service.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class MitraSecurityState {
  final bool isLoading;
  final String? error;

  // Data keamanan dari Firestore doc 'mitra/{uid}'
  final DateTime? lastPasswordChange;
  final bool pinEnabled;
  final bool emailVerified;
  final String email;

  const MitraSecurityState({
    this.isLoading = false,
    this.error,
    this.lastPasswordChange,
    this.pinEnabled = false,
    this.emailVerified = false,
    this.email = '',
  });

  MitraSecurityState copyWith({
    bool? isLoading,
    String? error,
    DateTime? lastPasswordChange,
    bool? pinEnabled,
    bool? emailVerified,
    String? email,
    bool clearError = false,
  }) {
    return MitraSecurityState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      emailVerified: emailVerified ?? this.emailVerified,
      email: email ?? this.email,
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final mitraSecurityControllerProvider =
    StateNotifierProvider<MitraSecurityController, MitraSecurityState>((ref) {
  return MitraSecurityController();
});

// ─── Controller ──────────────────────────────────────────────────────────────

class MitraSecurityController extends StateNotifier<MitraSecurityState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirestoreService.instance;

  MitraSecurityController() : super(const MitraSecurityState()) {
    _loadSecurityData();
  }

  User? get _currentUser => _auth.currentUser;
  String? get _uid => _currentUser?.uid;

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> _loadSecurityData() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _currentUser!.reload();

      final doc = await _firestore.collection('mitra').doc(uid).get();
      final data = doc.data() ?? {};

      final rawTs = data['lastPasswordChange'];
      DateTime? lastPwChange;
      if (rawTs is Timestamp) {
        lastPwChange = rawTs.toDate();
      } else if (rawTs is String) {
        lastPwChange = DateTime.tryParse(rawTs);
      }

      state = state.copyWith(
        isLoading: false,
        lastPasswordChange: lastPwChange,
        pinEnabled: data['pinEnabled'] ?? false,
        emailVerified: _auth.currentUser?.emailVerified ?? false,
        email: _auth.currentUser?.email ?? data['email'] ?? '',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _loadSecurityData();

  // ─── PIN ──────────────────────────────────────────────────────────────────

  /// Hash PIN sebelum simpan ke Firestore (SHA-256)
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Atur / ubah PIN (minimal 6 digit)
  Future<void> setPin(String pin) async {
    final uid = _uid;
    if (uid == null) throw Exception('User tidak ditemukan.');
    if (pin.length < 6) throw Exception('PIN minimal 6 digit.');

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final hashed = _hashPin(pin);

      await _firestore.collection('mitra').doc(uid).set({
        'pinEnabled': true,
        'pinHash': hashed,
        'pinUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log aktivitas
      await _addSecurityLog(
          SecurityLogType.pinChange, 'PIN keamanan diperbarui');

      state = state.copyWith(isLoading: false, pinEnabled: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Aktifkan / nonaktifkan PIN
  Future<void> togglePin(bool enabled) async {
    final uid = _uid;
    if (uid == null) throw Exception('User tidak ditemukan.');

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _firestore.collection('mitra').doc(uid).set({
        'pinEnabled': enabled,
        if (!enabled) 'pinHash': null,
      }, SetOptions(merge: true));

      await _addSecurityLog(
        SecurityLogType.pinChange,
        enabled ? 'PIN keamanan diaktifkan' : 'PIN keamanan dinonaktifkan',
      );

      state = state.copyWith(isLoading: false, pinEnabled: enabled);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Verifikasi PIN yang dimasukkan user
  Future<bool> verifyPin(String pin) async {
    final uid = _uid;
    if (uid == null) return false;

    final doc = await _firestore.collection('mitra').doc(uid).get();
    final storedHash = doc.data()?['pinHash'] as String?;
    if (storedHash == null) return false;
    return _hashPin(pin) == storedHash;
  }

  // ─── Email Verification ───────────────────────────────────────────────────

  Future<void> sendEmailVerification() async {
    final user = _currentUser;
    if (user == null) throw Exception('User tidak ditemukan.');
    if (user.emailVerified) throw Exception('Email sudah terverifikasi.');

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await user.sendEmailVerification();

      await _addSecurityLog(
        SecurityLogType.emailVerification,
        'Email verifikasi dikirim ke ${user.email}',
      );

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      if (e.code == 'too-many-requests') {
        throw Exception('Terlalu banyak permintaan. Coba lagi nanti.');
      }
      throw Exception('Gagal mengirim email verifikasi: ${e.message}');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> refreshEmailStatus() async {
    try {
      await _currentUser?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;
      state = state.copyWith(emailVerified: verified);

      if (verified) {
        final uid = _uid;
        if (uid != null) {
          await _firestore.collection('mitra').doc(uid).set(
            {'emailVerified': true},
            SetOptions(merge: true),
          );
        }
      }
    } catch (_) {}
  }

  // ─── Perangkat Login ──────────────────────────────────────────────────────

  Stream<List<MitraDeviceModel>> watchDevices() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('mitra_devices')
        .where('mitraId', isEqualTo: uid)
        .orderBy('lastActive', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MitraDeviceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Logout perangkat tertentu (hapus doc dari Firestore)
  Future<void> logoutDevice(String deviceId, String deviceName) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _firestore.collection('mitra_devices').doc(deviceId).delete();

      await _addSecurityLog(
        SecurityLogType.logout,
        'Keluar dari perangkat $deviceName',
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // ─── Security Logs ────────────────────────────────────────────────────────

  Stream<List<MitraSecurityLogModel>> watchSecurityLogs({int limit = 10}) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('mitra_security_logs')
        .where('mitraId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MitraSecurityLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> _addSecurityLog(SecurityLogType type, String details) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _firestore.collection('mitra_security_logs').add({
        'mitraId': uid,
        'type': type.name.replaceAllMapped(
            RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}'),
        'deviceName': 'Perangkat Saat Ini',
        'location': '',
        'timestamp': FieldValue.serverTimestamp(),
        'details': details,
      });
    } catch (_) {}
  }

  // ─── Update lastPasswordChange (dipanggil setelah ChangePasswordPage) ─────

  Future<void> markPasswordChanged() async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('mitra').doc(uid).set({
      'lastPasswordChange': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _addSecurityLog(
        SecurityLogType.passwordChange, 'Password berhasil diperbarui');

    state = state.copyWith(lastPasswordChange: DateTime.now());
  }

  // ─── Ubah Password ────────────────────────────────────────────────────────

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = _currentUser;
    if (user == null || user.email == null)
      throw Exception('User tidak ditemukan.');

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // 1. Re-autentikasi (Cek password lama)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Update ke password baru
      await user.updatePassword(newPassword);

      // 3. Catat ke Firestore & Log (Menggunakan fungsi yang sudah ada)
      await markPasswordChanged();

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Password lama yang Anda masukkan salah.');
      } else if (e.code == 'weak-password') {
        throw Exception(
            'Password baru terlalu lemah, gunakan kombinasi yang lebih kuat.');
      }
      throw Exception(e.message ?? 'Terjadi kesalahan pada server Firebase.');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
} // <--- PERHATIKAN: Kurung kurawal penutup class sekarang ada di paling bawah sini
