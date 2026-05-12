import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

// â”€â”€ Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class MitraProfileNotifier
    extends StateNotifier<AsyncValue<MitraProfileModel>> {
  final MitraService _service;

  MitraProfileNotifier(this._service) : super(const AsyncLoading()) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) loadProfile(uid);
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

  Future<void> updateBankInfo(String bankName, String bankAccount) async {
    if (state is! AsyncData) return;
    final updated = state.value!.copyWith(
      bankName: bankName,
      bankAccount: bankAccount,
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
      
      // Silent reload from server to ensure consistency
      await loadProfile(current.id, silent: true);
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

// Provider yang reaktif terhadap perubahan auth state
// Ini memastikan profil di-reset saat user ganti akun (logout/login)
final _profileAuthUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
});

final mitraProfileProvider = StateNotifierProvider<MitraProfileNotifier,
    AsyncValue<MitraProfileModel>>((ref) {
  final service = ref.watch(mitraServiceProvider);
  // Watch UID — saat UID berubah (ganti akun), provider ini otomatis di-recreate
  ref.watch(_profileAuthUidProvider);
  return MitraProfileNotifier(service);
});
