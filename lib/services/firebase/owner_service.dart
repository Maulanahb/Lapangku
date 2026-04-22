import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/models/owner/owner_field_model.dart';

class OwnerService {
  final FirebaseFirestore _firestore;

  OwnerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<OwnerFieldModel>> getOwnerFields(String ownerId) async {
    try {
      // Ini query utama untuk ambil lapangan milik si owner
      final snapshot = await _firestore
          .collection('fields')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      // Mapping data dari Firestore ke bentuk OwnerFieldModel
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return OwnerFieldModel(
          id: doc.id,
          ownerId: data['ownerId'] ?? '',
          name: data['name'] ?? '',
          location: data['location'] ?? '',
          pricePerHour: data['pricePerHour'] ?? 0,
          statusVerifikasi: data['statusVerifikasi'] ?? 'pending',
        );
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data lapangan: $e');
    }
  }

  Future<void> addField(OwnerFieldModel field) async {
    // TODO: Nanti diisi untuk form tambah lapangan
  }

  Future<void> updateField(OwnerFieldModel field) async {
    // TODO: Nanti diisi untuk form edit lapangan
  }

  Future<void> deleteField(String fieldId) async {
    // TODO: Nanti diisi untuk hapus lapangan
  }
}
