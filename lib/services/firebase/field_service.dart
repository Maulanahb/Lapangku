import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lapangku/models/field/field_model.dart';

class FieldService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'lapangku-db', // ✅ dipertahankan
  );

  Future<List<FieldModel>> getFields() async {
    final snapshot = await _db
        .collection('lapangan')
        .where('is_aktif', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => FieldModel.fromFirestore(doc))
        .toList();
  }

  Future<FieldModel> getFieldById(String id) async {
    final doc = await _db.collection('lapangan').doc(id).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Lapangan tidak ditemukan.');
    }
    return FieldModel.fromFirestore(doc);
  }

  Future<List<FieldModel>> getFieldsByKategori(String kategori) async {
    final snapshot = await _db
        .collection('lapangan')
        .where('is_aktif', isEqualTo: true)
        .where('kategori_lapangan', isEqualTo: kategori)
        .get();

    return snapshot.docs
        .map((doc) => FieldModel.fromFirestore(doc))
        .toList();
  }

  Future<List<FieldModel>> getFieldsByPemilik(String idPemilik) async {
    final snapshot = await _db
        .collection('lapangan')
        .where('id_pemilik', isEqualTo: idPemilik)
        .get();

    return snapshot.docs
        .map((doc) => FieldModel.fromFirestore(doc))
        .toList();
  }
}
