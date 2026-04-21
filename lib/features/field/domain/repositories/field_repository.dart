import '../entities/field_entity.dart';


abstract class FieldRepository {
  Future<List<FieldEntity>> getFields();
  Future<FieldEntity> getFieldById(String id);
  Future<List<FieldEntity>> getFieldsByKategori(String kategori);
  Future<List<FieldEntity>> getFieldsByPemilik(String idPemilik);
}