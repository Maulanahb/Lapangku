import '../../domain/entities/field_entity.dart';
import '../../domain/repositories/field_repository.dart';
import '../datasources/field_remote_datasource.dart';

class FieldRepositoryImpl implements FieldRepository {
  final FieldRemoteDataSource _datasource = FieldRemoteDataSourceImpl();

  @override
  Future<List<FieldEntity>> getFields() async {
    return await _datasource.getFields();
  }

  @override
  Future<FieldEntity> getFieldById(String id) async {
    return await _datasource.getFieldById(id);
  }

  @override
  Future<List<FieldEntity>> getFieldsByKategori(String kategori) async {
    return await _datasource.getFieldsByKategori(kategori);
  }

  @override
  Future<List<FieldEntity>> getFieldsByPemilik(String idPemilik) async {
    return await _datasource.getFieldsByPemilik(idPemilik);
  }
}