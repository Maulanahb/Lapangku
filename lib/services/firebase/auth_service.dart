import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      'avatarUrl': null, // Diupdate dari 'photoUrl' ke 'avatarUrl'
      'isVerified': false, // Diupdate dari 'statusVerifikasi' ke 'isVerified'
      'bankInfo': null,
      'idLapangan': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final data = await getUserData(user.uid);
    return UserModel.fromFirestore(data);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<Map<String, dynamic>> getUserData(String uid) async {
    // Tambahkan timeout agar tidak loading terus-menerus jika koneksi/Firestore bermasalah
    final doc = await _db.collection('users').doc(uid).get().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Waktu koneksi habis (Timeout). Cek internet/App Check kamu.'),
    );
    
    if (!doc.exists || doc.data() == null) {
      throw Exception('Data pengguna tidak ditemukan di database.');
    }
    return doc.data()!;
  }

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final data = await getUserData(user.uid);
      return UserModel.fromFirestore(data);
    });
  }
}
