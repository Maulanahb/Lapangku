import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user!;
}

  Future<User> register({
    required String email,
    required String password,
    required String name,
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
      'name': name,
      'phone': phone,
      'role': role,
      'photoUrl': null,
      'statusVerifikasi': role == 'mitra' ? 'proses' : null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return user;
  }

  Future<void> logout() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()!;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}