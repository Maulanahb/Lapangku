import 'dart:io';
import 'package:collection/collection.dart'; // Ditambahkan untuk firstWhereOrNull
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

// ─── State ─────────────────────────────────────────────────────────────────
class MitraFieldState {
  final AsyncValue<List<MitraFieldModel>> fields;
  final bool isMutating; 
  final String? errorMessage; // Tambahkan ini untuk handle error mutasi di UI

  const MitraFieldState({
    this.fields = const AsyncLoading(),
    this.isMutating = false,
    this.errorMessage,
  });

  MitraFieldState copyWith({
    AsyncValue<List<MitraFieldModel>>? fields,
    bool? isMutating,
    String? errorMessage,
  }) =>
      MitraFieldState(
        fields: fields ?? this.fields,
        isMutating: isMutating ?? this.isMutating,
        errorMessage: errorMessage, // Jika sukses, bisa di-set null kembali
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────
class MitraFieldNotifier extends StateNotifier<MitraFieldState> {
  final MitraService _service;
  final String _uid; // Passing UID dari provider agar lebih testable

  MitraFieldNotifier(this._service, this._uid) : super(const MitraFieldState()) {
    loadFields();
  }

  Future<void> loadFields() async {
    if (_uid.isEmpty) {
      state = state.copyWith(fields: const AsyncData([]));
      return;
    }
    state = state.copyWith(fields: const AsyncLoading(), errorMessage: null);
    try {
      final fields = await _service.getMitraFields(_uid);
      state = state.copyWith(fields: AsyncData(fields));
    } catch (e, st) {
      state = state.copyWith(fields: AsyncError(e, st));
    }
  }

  Future<bool> addField({
    required String namaVenue,
    required String namaLapangan,
    required String jenisLapangan,
    String tipeLapangan = 'Indoor',
    required int hargaPerJam,
    int? hargaWeekend,
    String jamBuka = '08:00',
    String jamTutup = '22:00',
    String deskripsi = '',
    String alamat = '',
    double latitude = 0.0,
    double longitude = 0.0,
    List<String> fasilitas = const [],
    List<File>? photoFiles,
  }) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      final field = MitraFieldModel(
        id: '',
        mitraId: _uid,
        namaVenue: namaVenue,
        namaLapangan: namaLapangan,
        jenisLapangan: jenisLapangan,
        tipeLapangan: tipeLapangan,
        hargaPerJam: hargaPerJam,
        hargaWeekend: hargaWeekend,
        jamBuka: jamBuka,
        jamTutup: jamTutup,
        deskripsi: deskripsi,
        alamat: alamat,
        latitude: latitude,
        longitude: longitude,
        fasilitas: fasilitas,
      );
      await _service.addField(field, photoFiles: photoFiles);
      await loadFields();
      return true; // Indikasi ke UI kalau proses berhasil
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false; // Indikasi ke UI kalau proses gagal
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<bool> editField(
    String fieldId, {
    required String namaVenue,
    required String namaLapangan,
    required String jenisLapangan,
    String tipeLapangan = 'Indoor',
    required int hargaPerJam,
    int? hargaWeekend,
    String jamBuka = '08:00',
    String jamTutup = '22:00',
    String deskripsi = '',
    String alamat = '',
    double latitude = 0.0,
    double longitude = 0.0,
    List<String> fasilitas = const [],
    List<String> photoUrls = const [],
    List<File>? newPhotoFiles,
  }) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      final currentFields = state.fields.value ?? [];
      
      // Menggunakan firstWhereOrNull untuk menghindari StateError crash
      final existingField = currentFields.firstWhereOrNull((f) => f.id == fieldId);
      if (existingField == null) {
        throw Exception("Lapangan tidak ditemukan.");
      }

      final updatedField = existingField.copyWith(
        namaVenue: namaVenue,
        namaLapangan: namaLapangan,
        jenisLapangan: jenisLapangan,
        tipeLapangan: tipeLapangan,
        hargaPerJam: hargaPerJam,
        hargaWeekend: hargaWeekend,
        jamBuka: jamBuka,
        jamTutup: jamTutup,
        deskripsi: deskripsi,
        alamat: alamat,
        latitude: latitude,
        longitude: longitude,
        fasilitas: fasilitas,
        photoUrls: photoUrls,
      );
      await _service.updateField(updatedField, newPhotoFiles: newPhotoFiles);
      await loadFields();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<bool> deleteField(String fieldId) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      await _service.deleteField(fieldId);
      await loadFields();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<void> toggleFieldStatus(String fieldId, bool currentStatus) async {
    final newStatus = !currentStatus;
    final currentList = state.fields.value ?? [];
    final updated = currentList
        .map((f) => f.id == fieldId ? f.copyWith(isActive: newStatus) : f)
        .toList();
    state = state.copyWith(fields: AsyncData(updated));
    try {
      await _service.toggleFieldStatus(fieldId, isActive: newStatus);
    } catch (_) {
      state = state.copyWith(fields: AsyncData(currentList));
      rethrow;
    }
  }
}

final mitraFieldProvider =
    StateNotifierProvider<MitraFieldNotifier, MitraFieldState>((ref) {
  final service = ref.watch(mitraServiceProvider);
  final uid = ref.watch(currentUidProvider);
  
  return MitraFieldNotifier(service, uid);
});

// Perbaikan penulisan nama ke camelCase
final mitraFieldListProvider =
    Provider<AsyncValue<List<MitraFieldModel>>>((ref) {
  return ref.watch(mitraFieldProvider).fields;
});