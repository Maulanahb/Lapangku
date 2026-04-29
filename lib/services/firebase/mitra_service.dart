import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/models/Mitra/Mitra_field_model.dart';

class MitraService {
  final FirebaseFirestore _firestore;

  MitraService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<MitraFieldModel>> getMitraFields(String MitraId) async {
    try {
      // Ini query utama untuk ambil lapangan milik si Mitra
      final snapshot = await _firestore
          .collection('fields')
          .where('MitraId', isEqualTo: MitraId)
          .get();

      // Mapping data dari Firestore ke bentuk MitraFieldModel
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MitraFieldModel(
          id: doc.id,
          MitraId: data['MitraId'] ?? '',
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

  Future<void> addField(MitraFieldModel field) async {
    // TODO: Nanti diisi untuk form tambah lapangan
  }

  Future<void> updateField(MitraFieldModel field) async {
    // TODO: Nanti diisi untuk form edit lapangan
  }

  Future<void> deleteField(String fieldId) async {
    // TODO: Nanti diisi untuk hapus lapangan
  }
}
