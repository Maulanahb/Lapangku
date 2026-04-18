import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/field_repository_impl.dart';
import '../../domain/entities/field_entity.dart';
import '../../domain/repositories/field_repository.dart';

final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  return FieldRepositoryImpl();
});

final fieldsProvider = FutureProvider<List<FieldEntity>>((ref) async {
  final repository = ref.watch(fieldRepositoryProvider);
  return repository.getFields();
});

final fieldDetailProvider = FutureProvider.family<FieldEntity, String>((ref, id) async {
  final repository = ref.watch(fieldRepositoryProvider);
  return repository.getFieldById(id);
});