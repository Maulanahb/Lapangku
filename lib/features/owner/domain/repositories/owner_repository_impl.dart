import '../../domain/entities/field_entity.dart';
import '../../domain/repositories/owner_repository.dart';
import '../../data/datasources/owner_remote_data_source.dart';

class OwnerRepositoryImpl implements OwnerRepository {
  final OwnerRemoteDataSource remoteDataSource;

  OwnerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FieldEntity>> getOwnerFields(String ownerId) async {
    try {
      // Minta data ke Firestore lewat Data Source
      return await remoteDataSource.getOwnerFields(ownerId);
    } catch (e) {
      throw Exception('Gagal memuat lapangan: $e');
    }
  }

  @override
  Future<void> addField(FieldEntity field) async {
    // TODO: Nanti diisi untuk form tambah lapangan
  }

  @override
  Future<void> updateField(FieldEntity field) async {
    // TODO: Nanti diisi untuk form edit lapangan
  }

  @override
  Future<void> deleteField(String fieldId) async {
    // TODO: Nanti diisi untuk hapus lapangan
  }
}