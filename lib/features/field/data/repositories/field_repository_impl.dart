import '../../domain/entities/field_entity.dart';
import '../../domain/repositories/field_repository.dart';
import '../datasources/field_remote_datasource.dart';

class FieldRepositoryImpl implements FieldRepository {
  final _datasource = FieldRemoteDatasource();

  @override
  Future<List<FieldEntity>> getFields() async {
    final data = await _datasource.getFields();
    return data.map((d) => _toEntity(d)).toList();
  }

  @override
  Future<FieldEntity> getFieldById(String id) async {
    final data = await _datasource.getFieldById(id);
    return _toEntity(data);
  }

  FieldEntity _toEntity(Map<String, dynamic> d) {
    return FieldEntity(
      id: d['id'] ?? '',
      nama: d['nama_lapangan'] ?? '',
      kategori: d['kategori'] ?? '',
      hargaPerJam: (d['harga_per_jam'] ?? 0).toInt(),
      alamat: d['alamat'] ?? '',
      latitude: (d['latitude'] ?? 0).toDouble(),
      longitude: (d['longitude'] ?? 0).toDouble(),
      deskripsi: d['deskripsi'] ?? '',
      isAktif: d['is_aktif'] ?? false,
      ratingAvg: (d['rating_avg'] ?? 0).toDouble(),
      totalUlasan: (d['total_ulasan'] ?? 0).toInt(),
      fotoUtama: d['foto_utama'] ?? '',
      fotoGaleri: List<String>.from(d['foto_galeri'] ?? []),
      fasilitas: List<String>.from(d['fasilitas'] ?? []),
      idPemilik: d['id_pemilik'] ?? '',
    );
  }
}