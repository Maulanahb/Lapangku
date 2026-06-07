import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/core/services/firestore_service.dart';

final customerSecurityControllerProvider = StateNotifierProvider<CustomerSecurityController, AsyncValue<void>>((ref) {
  return CustomerSecurityController();
});

// Controller untuk mengelola keamanan akun Customer (Password, Verifikasi Email, OTP, Perangkat Login)
class CustomerSecurityController extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirestoreService.instance;

  CustomerSecurityController() : super(const AsyncData(null));

  User? get currentUser => _auth.currentUser;

  // --- 1. UBAH PASSWORD ---
  // Mengganti password lama dengan password baru
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      state = const AsyncLoading();
      
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('User tidak ditemukan atau email tidak valid.');
      }

      // Re-authenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Update lastPasswordChange di Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'lastPasswordChange': FieldValue.serverTimestamp(),
      });

      // Update user model state via authProvider
      // _ref.read(authProvider.notifier).refreshUser();

      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan saat mengubah password.';
      if (e.code == 'wrong-password') {
        message = 'Password lama tidak valid.';
      } else if (e.code == 'weak-password') {
        message = 'Password baru terlalu lemah.';
      }
      state = AsyncError(message, StackTrace.current);
      throw Exception(message);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      throw Exception('Terjadi kesalahan yang tidak terduga.');
    }
  }

  // --- 2. VERIFIKASI EMAIL ---
  // Mengirim email berisi tautan verifikasi
  Future<void> sendEmailVerification() async {
    try {
      state = const AsyncLoading();
      
      final user = currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan.');
      }

      if (user.emailVerified) {
        throw Exception('Email sudah terverifikasi.');
      }

      await user.sendEmailVerification();
      
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal mengirim email verifikasi. Coba lagi nanti.';
      if (e.code == 'too-many-requests') {
        message = 'Terlalu banyak permintaan. Coba lagi nanti.';
      }
      state = AsyncError(message, StackTrace.current);
      throw Exception(message);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      throw Exception('Terjadi kesalahan yang tidak terduga.');
    }
  }

  // Mengecek apakah user sudah berhasil memverifikasi emailnya
  Future<void> refreshEmailVerificationStatus() async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
           await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
          });
          // _ref.read(authProvider.notifier).refreshUser();
        }
      }
    } catch (e) {
      // Ignore background reload errors
      developer.log('Error refreshing email verification status: $e');
    }
  }

  // --- 3. VERIFIKASI NOMOR HP ---
  // Memverifikasi kode OTP SMS yang dimasukkan
  Future<void> verifyPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      state = const AsyncLoading();
      
      final user = currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan.');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Link credential if phone number is different, or just verify
      // For simplicity, we just verify the credential and update firestore
      // Usually you'd link it, but Firebase limits linking to 1 phone per account
      // Let's assume we link it if not already linked, or just check validity.
      try {
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // If already linked or credential already in use by same user, it might fail.
        if (e.code == 'credential-already-in-use') {
          // Already linked, we can consider it verified
        } else {
          rethrow;
        }
      }

      await _firestore.collection('users').doc(user.uid).update({
        'phoneVerified': true,
      });

      // _ref.read(authProvider.notifier).refreshUser();

      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      if (e is Exception) rethrow;
      throw Exception('OTP tidak valid atau kadaluarsa.');
    }
  }

  // --- 4. PERANGKAT LOGIN ---
  // Mengambil daftar perangkat (device) yang pernah digunakan untuk login
  Stream<List<Map<String, dynamic>>> getUserDevices() {
    final user = currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
        .collection('user_devices')
        .where('userId', isEqualTo: user.uid)
        .orderBy('lastActive', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }


}
