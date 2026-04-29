import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/mitra/field/models/mitra_field_model.dart';
import 'package:lapangku/features/mitra/field/repositories/mitra_field_repository.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

// ── Service & Repository Providers ────────────────────────────────
final MitraServiceProvider = Provider<MitraService>((ref) => MitraService());

final MitraFieldRepositoryProvider = Provider<MitraFieldRepository>(
    (ref) => MitraFieldRepository(ref.watch(MitraServiceProvider)));

// ── State ──────────────────────────────────────────────────────────
class MitraFieldState {
  final AsyncValue<List<MitraFieldModel>> fields;
  final bool isMutating; // loading untuk add/edit/delete

  const MitraFieldState({
    this.fields = const AsyncLoading(),
    this.isMutating = false,
  });

  MitraFieldState copyWith({
    AsyncValue<List<MitraFieldModel>>? fields,
    bool? isMutating,
  }) =>
      MitraFieldState(
        fields: fields ?? this.fields,
        isMutating: isMutating ?? this.isMutating,
      );
}

// ── Notifier ───────────────────────────────────────────────────────
class MitraFieldNotifier extends StateNotifier<MitraFieldState> {
  final MitraFieldRepository _repository;

  MitraFieldNotifier(this._repository) : super(const MitraFieldState()) {
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
      final field = MitraFieldModel(
        id: '',
        MitraId: _uid,
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

final mitraFieldProvider =
    StateNotifierProvider<MitraFieldNotifier, MitraFieldState>((ref) {
  final repo = ref.watch(MitraFieldRepositoryProvider);
  return MitraFieldNotifier(repo);
});

// Convenience getter
final MitraFieldListProvider = Provider<AsyncValue<List<MitraFieldModel>>>((ref) {
  return ref.watch(mitraFieldProvider).fields;
});
