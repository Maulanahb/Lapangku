import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FieldRemoteDatasource {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'lapangku-db',
  );

  Future<List<Map<String, dynamic>>> getFields() async {
    final snapshot = await _db
        .collection('lapangan')
        .where('is_aktif', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, dynamic>> getFieldById(String id) async {
    final doc = await _db.collection('lapangan').doc(id).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Lapangan tidak ditemukan.');
    }
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }
}