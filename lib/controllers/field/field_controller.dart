import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/services/firebase/field_service.dart';

final fieldServiceProvider = Provider<FieldService>((ref) {
  return FieldService();
});

final fieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  final service = ref.watch(fieldServiceProvider);
  return service.getFields();
});

final fieldDetailProvider = FutureProvider.family<FieldModel, String>((ref, id) async {
  final service = ref.watch(fieldServiceProvider);
  return service.getFieldById(id);
});
