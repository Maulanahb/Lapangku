import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/models/auth/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirestoreService.instance;

  Future<UserModel> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user!;
    final data = await getUserData(user.uid);
    return UserModel.fromFirestore(data);
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String nama,
    required String phone,
    required String role,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user!;

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'nama': nama,
      'phone': phone,
      'role': role,
      'avatarUrl': null,
      'isVerified': false,
      'statusVerifikasi': role == 'mitra' ? 'menunggu' : 'aktif',
      'bankInfo': null,
      'idLapangan': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final data = await getUserData(user.uid);
    return UserModel.fromFirestore(data);
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      // 1. Memicu proses autentikasi Google
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '1050784867568-a5m3diru6nburol3jt1t7238bkg9vors.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Login dibatalkan pengguna');
      }

      // 2. Mendapatkan detail autentikasi dari permintaan
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Membuat kredensial baru
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase dengan kredensial tersebut
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Gagal mendapatkan informasi pengguna dari Google');
      }

      // 5. Cek apakah user sudah ada di Firestore
      final docRef = _db.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        // Jika belum ada, buat dokumen baru dengan role default 'customer'
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? googleUser.email,
          'nama': user.displayName ?? googleUser.displayName ?? 'User Google',
          'role': 'customer',
          'phone': user.phoneNumber,
          'avatarUrl': user.photoURL ?? googleUser.photoUrl,
          'isVerified': false,
          'bankInfo': null,
          'idLapangan': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 6. Ambil data dari Firestore untuk direturn sebagai UserModel
      final data = await getUserData(user.uid);
      return UserModel.fromFirestore(data);
    } catch (e) {
      throw Exception('Gagal login dengan Google: $e');
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // Ignore error if not signed in with google
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    // 1. Update Firestore
    await _db.collection('users').doc(uid).update({
      'nama': name,
      'email': email,
      'phone': phone,
    }).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Waktu koneksi habis. Periksa internet Anda.');
    });

    // 2. Update FirebaseAuth email if it changed (might require re-auth in some cases)
    final user = _auth.currentUser;
    if (user != null && user.email != email) {
      try {
        await user.verifyBeforeUpdateEmail(email).timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception('Waktu koneksi habis saat update email.');
        });
      } catch (e) {
        // We log or throw if we strictly want to enforce email update
        throw Exception('Gagal mengubah email Auth: $e');
      }
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Pengguna tidak terautentikasi.');

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(cred).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Waktu koneksi habis saat verifikasi password.');
      });
      await user.updatePassword(newPassword).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Waktu koneksi habis saat mengubah password.');
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Password lama salah.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Kredensial tidak valid atau akun Google/SSO.');
      }
      throw Exception('Gagal mengubah password: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<Map<String, dynamic>> getUserData(String uid) async {
    // Coba ambil dari server dulu, jika timeout fallback ke cache
    try {
      final doc = await _db.collection('users').doc(uid).get(
        const GetOptions(source: Source.serverAndCache),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Waktu koneksi habis (Timeout). Cek internet kamu.'),
      );
      
      if (!doc.exists || doc.data() == null) {
        throw Exception('Data pengguna tidak ditemukan di database.');
      }
      return doc.data()!;
    } catch (e) {
      // Jika gagal dari server, coba dari cache lokal
      if (e.toString().contains('Timeout') || e.toString().contains('koneksi')) {
        try {
          final cachedDoc = await _db.collection('users').doc(uid).get(
            const GetOptions(source: Source.cache),
          );
          if (cachedDoc.exists && cachedDoc.data() != null) {
            return cachedDoc.data()!;
          }
        } catch (_) {
          // Cache juga kosong, lempar error asli
        }
      }
      rethrow;
    }
  }

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final data = await getUserData(user.uid);
        return UserModel.fromFirestore(data);
      } catch (e) {
        return null;
      }
    });
  }
}
