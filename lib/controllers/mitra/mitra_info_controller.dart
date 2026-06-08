import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/core/services/firestore_service.dart';

final mitraInfoControllerProvider = StateNotifierProvider<MitraInfoController, AsyncValue<void>>((ref) {
  return MitraInfoController();
});

// Controller untuk mengelola informasi profil dan bisnis Mitra
class MitraInfoController extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirestoreService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  MitraInfoController() : super(const AsyncData(null));

  User? get currentUser => _auth.currentUser;

  // Menyimpan pembaruan data profil Mitra ke database
  Future<void> updateProfile({
    required String namaLengkap, 
    required String nomorHp,
    required String alamatDomisili,
    required String nomorKtp,
    required String namaPemilikBisnis,
  }) async {
    try {
      state = const AsyncLoading();
      final user = currentUser;
      if (user == null) throw Exception('User tidak ditemukan.');

      await _firestore.collection('mitra').doc(user.uid).update({
        'MitraName': namaLengkap, 
        'ownerName': namaLengkap, 
        'businessName': namaPemilikBisnis, 
        'namaBisnis': namaPemilikBisnis,
        'phone': nomorHp,
        'whatsapp': nomorHp,
        'alamat': alamatDomisili,
        'nomorKtp': nomorKtp,
      });

      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      throw Exception('Gagal menyimpan profil: $e');
    }
  }

  // Mengunggah gambar profil/logo Mitra ke Firebase Storage
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      state = const AsyncLoading();
      final user = currentUser;
      if (user == null) throw Exception('User tidak ditemukan.');

      final ref = _storage.ref().child('mitra/logos/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('mitra').doc(user.uid).update({
        'logoUrl': downloadUrl,
        'fotoLogo': downloadUrl,
      });

      state = const AsyncData(null);
      return downloadUrl;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      throw Exception('Gagal mengunggah foto profil: $e');
    }
  }

  // Mengambil daftar lapangan yang didaftarkan oleh Mitra secara real-time
  Stream<List<MitraFieldModel>> getLapanganTerdaftar(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    
    return _firestore
        .collection('lapangan')
        .where('mitraId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MitraFieldModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
