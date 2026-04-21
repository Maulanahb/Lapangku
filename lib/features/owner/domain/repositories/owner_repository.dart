import '../entities/field_entity.dart';

abstract class OwnerRepository {
  // Mengambil daftar lapangan
  Future<List<FieldEntity>> getOwnerFields(String ownerId); 
  
  // Nanti kita tambahkan fitur CRUD lainnya bertahap
  Future<void> addField(FieldEntity field);
  Future<void> updateField(FieldEntity field);
  Future<void> deleteField(String fieldId);
}