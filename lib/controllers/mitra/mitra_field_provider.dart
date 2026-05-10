import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

// â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

// â”€â”€ Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class MitraFieldNotifier extends StateNotifier<MitraFieldState> {
  final MitraService _service;

  MitraFieldNotifier(this._service) : super(const MitraFieldState()) {
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
      final fields = await _service.getMitraFields(_uid);
      state = state.copyWith(fields: AsyncData(fields));
    } catch (e, st) {
      state = state.copyWith(fields: AsyncError(e, st));
    }
  }

  Future<void> addField({
    required String namaVenue,
    required String namaLapangan,
    required String jenisLapangan,
    required int hargaPerJam,
    int? hargaWeekend,
    String jamBuka = '08:00',
    String jamTutup = '22:00',
    String deskripsi = '',
    String alamat = '',
    List<String> fasilitas = const [],
    List<File>? photoFiles,
  }) async {
    state = state.copyWith(isMutating: true);
    try {
      final field = MitraFieldModel(
        id: '',
        mitraId: _uid,
        namaVenue: namaVenue,
        namaLapangan: namaLapangan,
        jenisLapangan: jenisLapangan,
        hargaPerJam: hargaPerJam,
        hargaWeekend: hargaWeekend,
        jamBuka: jamBuka,
        jamTutup: jamTutup,
        deskripsi: deskripsi,
        alamat: alamat,
        fasilitas: fasilitas,
      );
      await _service.addField(field, photoFiles: photoFiles);
      await loadFields();
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<void> editField(
    String fieldId, {
    required String namaVenue,
    required String namaLapangan,
    required String jenisLapangan,
    required int hargaPerJam,
    int? hargaWeekend,
    String jamBuka = '08:00',
    String jamTutup = '22:00',
    String deskripsi = '',
    String alamat = '',
    List<String> fasilitas = const [],
    List<String> photoUrls = const [],
    List<File>? newPhotoFiles,
  }) async {
    state = state.copyWith(isMutating: true);
    try {
      final currentFields = state.fields.value ?? [];
      final existingField = currentFields.firstWhere((f) => f.id == fieldId);
      final updatedField = existingField.copyWith(
        namaVenue: namaVenue,
        namaLapangan: namaLapangan,
        jenisLapangan: jenisLapangan,
        hargaPerJam: hargaPerJam,
        hargaWeekend: hargaWeekend,
        jamBuka: jamBuka,
        jamTutup: jamTutup,
        deskripsi: deskripsi,
        alamat: alamat,
        fasilitas: fasilitas,
        photoUrls: photoUrls,
      );
      await _service.updateField(updatedField, newPhotoFiles: newPhotoFiles);
      await loadFields();
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<void> deleteField(String fieldId) async {
    state = state.copyWith(isMutating: true);
    try {
      await _service.deleteField(fieldId);
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
      await _service.toggleFieldStatus(fieldId, newStatus);
    } catch (_) {
      // Revert
      state = state.copyWith(fields: AsyncData(currentList));
      rethrow;
    }
  }
}

// Provider yang reaktif terhadap perubahan auth state
// Ini memastikan data di-reset saat user ganti akun (logout/login)
final _authUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
});

final mitraFieldProvider =
    StateNotifierProvider<MitraFieldNotifier, MitraFieldState>((ref) {
  final service = ref.watch(mitraServiceProvider);
  // Watch UID — saat UID berubah (ganti akun), provider ini otomatis di-recreate
  ref.watch(_authUidProvider);
  return MitraFieldNotifier(service);
});

// Convenience getter
final MitraFieldListProvider =
    Provider<AsyncValue<List<MitraFieldModel>>>((ref) {
  return ref.watch(mitraFieldProvider).fields;
});
