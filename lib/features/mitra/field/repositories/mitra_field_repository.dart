import 'dart:io';
import 'package:lapangku/features/mitra/field/models/mitra_field_model.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

class MitraFieldRepository {
  final MitraService _service;

  MitraFieldRepository(this._service);

  Future<List<MitraFieldModel>> getFields(String MitraId) =>
      _service.getMitraFields(MitraId);

  Stream<List<MitraFieldModel>> streamFields(String MitraId) =>
      _service.streamMitraFields(MitraId);

  Future<String> addField(MitraFieldModel field,
          {List<File>? photoFiles}) =>
      _service.addField(field, photoFiles: photoFiles);

  Future<void> updateField(MitraFieldModel field,
          {List<File>? newPhotoFiles}) =>
      _service.updateField(field, newPhotoFiles: newPhotoFiles);

  Future<void> deleteField(String fieldId) => _service.deleteField(fieldId);

  Future<void> toggleStatus(String fieldId, bool isActive) =>
      _service.toggleFieldStatus(fieldId, isActive);
}
