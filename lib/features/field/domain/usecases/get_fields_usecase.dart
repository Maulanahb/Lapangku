import '../entities/field_entity.dart';
import '../repositories/field_repository.dart';

class GetFieldsUseCase {
  final FieldRepository repository;
  GetFieldsUseCase(this.repository);

  Future<List<FieldEntity>> call() => repository.getFields();
}