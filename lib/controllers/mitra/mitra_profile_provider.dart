import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

// ─── Notifier ──────────────────────────────────────────────────────────────
class MitraProfileNotifier
    extends StateNotifier<AsyncValue<MitraProfileModel>> {
  final MitraService _service;
  final String _uid;

  MitraProfileNotifier(this._service, this._uid) : super(const AsyncLoading()) {
    if (_uid.isNotEmpty) loadProfile(_uid);
  }

  Future<void> loadProfile(String uid, {bool silent = false}) async {
    if (!silent) state = const AsyncLoading();
    try {
      final profile = await _service.getProfile(uid);
      state = AsyncData(profile);
    } catch (e, st) {
      if (!silent) state = AsyncError(e, st);
    }
  }

  Future<void> updateProfile({
    required String businessName,
    required String MitraName,
    required String email,
    required String phone,
    String? alamat,
    String? description,
  }) async {
    if (state is! AsyncData) return;
    final current = state.value!;
    final updated = current.copyWith(
      businessName: businessName,
      MitraName: MitraName,
      email: email,
      phone: phone,
      alamat: alamat,
      description: description,
    );
    try {
      await _service.updateProfile(updated);
      state = AsyncData(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBankInfo(String bankName, String bankAccount, String bankAccountName) async {
    if (state is! AsyncData) return;
    final updated = state.value!.copyWith(
      bankName: bankName,
      bankAccount: bankAccount,
      bankAccountName: bankAccountName,
    );
    try {
      await _service.updateProfile(updated);
      state = AsyncData(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleNotificationOrder() async {
    if (state is! AsyncData) return;
    final current = state.value!;
    final newVal = !current.notificationOrder;
    state = AsyncData(current.copyWith(notificationOrder: newVal));
    try {
      await _service.updateNotificationSettings(
        current.id,
        orderNotif: newVal,
        promoNotif: current.notificationPromo,
      );
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> toggleNotificationPromo() async {
    if (state is! AsyncData) return;
    final current = state.value!;
    final newVal = !current.notificationPromo;
    state = AsyncData(current.copyWith(notificationPromo: newVal));
    try {
      await _service.updateNotificationSettings(
        current.id,
        orderNotif: current.notificationOrder,
        promoNotif: newVal,
      );
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> uploadLogo(File image) async {
    if (state is! AsyncData) return;
    final current = state.value!;
    try {
      final url = await _service.uploadLogo(current.id, image);
      final updated = current.copyWith(logoUrl: url);

      // Update Firestore first
      await _service.updateProfile(updated);

      // Update local state immediately
      state = AsyncData(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLogo() async {
    if (state is! AsyncData) return;
    final current = state.value!;
    try {
      final updated = current.copyWith(logoUrl: '');

      // Update Firestore
      await _service.updateProfile(updated);

      // Update local state immediately
      state = AsyncData(updated);
    } catch (e) {
      rethrow;
    }
  }


  Future<void> uploadDocument(String docType, File file) async {
    if (state is! AsyncData) return;
    final current = state.value!;
    try {
      final url = await _service.uploadDocument(current.id, docType, file);
      MitraProfileModel updated;
      if (docType.toLowerCase() == 'ktp') {
        updated = current.copyWith(ktpUrl: url);
      } else {
        updated = current.copyWith(npwpUrl: url);
      }
      await _service.updateProfile(updated);
      state = AsyncData(updated);
    } catch (e) {
      rethrow;
    }
  }
}

final mitraProfileProvider = StateNotifierProvider<MitraProfileNotifier,
    AsyncValue<MitraProfileModel>>((ref) {
  final service = ref.watch(mitraServiceProvider);
  final uid = ref.watch(currentUidProvider);
  return MitraProfileNotifier(service, uid);
});
