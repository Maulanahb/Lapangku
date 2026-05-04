import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/core/services/firestore_service.dart';

class FavoriteService {
  final FirebaseFirestore _db = FirestoreService.instance;

  /// Referensi ke subcollection favorites milik user
  CollectionReference _favRef(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  /// Tambah lapangan ke favorit
  Future<void> addFavorite(String uid, String fieldId) async {
    await _favRef(uid).doc(fieldId).set({
      'fieldId': fieldId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hapus lapangan dari favorit
  Future<void> removeFavorite(String uid, String fieldId) async {
    await _favRef(uid).doc(fieldId).delete();
  }

  /// Cek apakah lapangan sudah difavoritkan
  Future<bool> isFavorited(String uid, String fieldId) async {
    final doc = await _favRef(uid).doc(fieldId).get();
    return doc.exists;
  }

  /// Stream real-time status favorit sebuah lapangan
  Stream<bool> watchIsFavorited(String uid, String fieldId) {
    return _favRef(uid).doc(fieldId).snapshots().map((doc) => doc.exists);
  }

  /// Stream real-time daftar ID lapangan favorit
  Stream<List<String>> watchFavoriteIds(String uid) {
    return _favRef(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// Ambil jumlah favorit (untuk profil)
  Future<int> getFavoritesCount(String uid) async {
    final snap = await _favRef(uid).get();
    return snap.size;
  }
}
