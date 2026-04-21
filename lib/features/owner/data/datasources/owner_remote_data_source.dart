import 'package:cloud_firestore/cloud_firestore.dart';
// TODO: Jangan lupa import FieldEntity kamu di sini
// import '../../domain/entities/field_entity.dart';
import '../../domain/entities/field_entity.dart';

abstract class OwnerRemoteDataSource {
  Future<List<FieldEntity>> getOwnerFields(String ownerId);
}

class OwnerRemoteDataSourceImpl implements OwnerRemoteDataSource {
  final FirebaseFirestore firestore;

  OwnerRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<FieldEntity>> getOwnerFields(String ownerId) async {
    try {
      // Ini query utama untuk ambil lapangan milik si owner
      final snapshot = await firestore
          .collection('fields')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      // Mapping data dari Firestore ke bentuk FieldEntity
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FieldEntity(
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
}