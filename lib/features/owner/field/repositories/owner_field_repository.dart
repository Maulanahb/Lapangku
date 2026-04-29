import 'dart:io';
import 'package:lapangku/features/owner/field/models/owner_field_model.dart';
import 'package:lapangku/services/firebase/owner_service.dart';

class OwnerFieldRepository {
  final OwnerService _service;

  OwnerFieldRepository(this._service);

  Future<List<OwnerFieldModel>> getFields(String ownerId) =>
      _service.getOwnerFields(ownerId);

  Stream<List<OwnerFieldModel>> streamFields(String ownerId) =>
      _service.streamOwnerFields(ownerId);

  Future<String> addField(OwnerFieldModel field,
          {List<File>? photoFiles}) =>
      _service.addField(field, photoFiles: photoFiles);

  Future<void> updateField(OwnerFieldModel field,
          {List<File>? newPhotoFiles}) =>
      _service.updateField(field, newPhotoFiles: newPhotoFiles);

  Future<void> deleteField(String fieldId) => _service.deleteField(fieldId);

  Future<void> toggleStatus(String fieldId, bool isActive) =>
      _service.toggleFieldStatus(fieldId, isActive);
}
