import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/owner/field/models/owner_field_model.dart';
import 'package:lapangku/features/owner/field/repositories/owner_field_repository.dart';
import 'package:lapangku/services/firebase/owner_service.dart';

// ── Service & Repository Providers ────────────────────────────────
final ownerServiceProvider = Provider<OwnerService>((ref) => OwnerService());

final ownerFieldRepositoryProvider = Provider<OwnerFieldRepository>(
    (ref) => OwnerFieldRepository(ref.watch(ownerServiceProvider)));

// ── State ──────────────────────────────────────────────────────────
class OwnerFieldState {
  final AsyncValue<List<OwnerFieldModel>> fields;
  final bool isMutating; // loading untuk add/edit/delete

  const OwnerFieldState({
    this.fields = const AsyncLoading(),
    this.isMutating = false,
  });

  OwnerFieldState copyWith({
    AsyncValue<List<OwnerFieldModel>>? fields,
    bool? isMutating,
  }) =>
      OwnerFieldState(
        fields: fields ?? this.fields,
        isMutating: isMutating ?? this.isMutating,
      );
}

// ── Notifier ───────────────────────────────────────────────────────
class OwnerFieldNotifier extends StateNotifier<OwnerFieldState> {
  final OwnerFieldRepository _repository;

  OwnerFieldNotifier(this._repository) : super(const OwnerFieldState()) {
    loadFields();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> loadFields() async {
    if (_uid.isEmpty) {
      state = state.copyWith(fields: const AsyncData([]));
      return;
    }
    state = state.copyWith(fields: const AsyncLoading());
    try {
      final fields = await _repository.getFields(_uid);
      state = state.copyWith(fields: AsyncData(fields));
    } catch (e, st) {
      state = state.copyWith(fields: AsyncError(e, st));
    }
  }

  Future<void> addField({
    required String namaLapangan,
    required String jenisLapangan,
    required int hargaPerJam,
    String deskripsi = '',
    String alamat = '',
    List<String> fasilitas = const [],
    List<File>? photoFiles,
  }) async {
    state = state.copyWith(isMutating: true);
    try {
      final field = OwnerFieldModel(
        id: '',
        ownerId: _uid,
        namaLapangan: namaLapangan,
        jenisLapangan: jenisLapangan,
        hargaPerJam: hargaPerJam,
        deskripsi: deskripsi,
        alamat: alamat,
        fasilitas: fasilitas,
      );
      await _repository.addField(field, photoFiles: photoFiles);
      await loadFields();
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<void> editField(
    String fieldId, {
    required String namaLapangan,
    required int hargaPerJam,
    String deskripsi = '',
    List<String> fasilitas = const [],
    List<File>? newPhotoFiles,
  }) async {
    state = state.copyWith(isMutating: true);
    try {
      final currentFields = state.fields.value ?? [];
      final existingField = currentFields.firstWhere((f) => f.id == fieldId);
      final updatedField = existingField.copyWith(
        namaLapangan: namaLapangan,
        hargaPerJam: hargaPerJam,
        deskripsi: deskripsi,
        fasilitas: fasilitas,
      );
      await _repository.updateField(updatedField, newPhotoFiles: newPhotoFiles);
      await loadFields();
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<void> deleteField(String fieldId) async {
    state = state.copyWith(isMutating: true);
    try {
      await _repository.deleteField(fieldId);
      await loadFields();
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<void> toggleFieldStatus(String fieldId, bool currentStatus) async {
    final newStatus = !currentStatus;
    // Optimistic update
    final currentList = state.fields.value ?? [];
    final updated = currentList
        .map((f) => f.id == fieldId ? f.copyWith(isActive: newStatus) : f)
        .toList();
    state = state.copyWith(fields: AsyncData(updated));
    try {
      await _repository.toggleStatus(fieldId, newStatus);
    } catch (_) {
      // Revert
      state = state.copyWith(fields: AsyncData(currentList));
      rethrow;
    }
  }
}

final ownerFieldProvider =
    StateNotifierProvider<OwnerFieldNotifier, OwnerFieldState>((ref) {
  final repo = ref.watch(ownerFieldRepositoryProvider);
  return OwnerFieldNotifier(repo);
});

// Convenience getter
final ownerFieldListProvider = Provider<AsyncValue<List<OwnerFieldModel>>>((ref) {
  return ref.watch(ownerFieldProvider).fields;
});
