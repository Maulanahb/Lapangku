import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/Mitra/profile/models/Mitra_profile_model.dart';
import 'package:lapangku/features/Mitra/profile/repositories/Mitra_profile_repository.dart';
import 'package:lapangku/services/firebase/Mitra_service.dart';

final _MitraSvcProvider = Provider<MitraService>((ref) => MitraService());

final MitraProfileRepositoryProvider = Provider<MitraProfileRepository>(
    (ref) => MitraProfileRepository(ref.watch(_MitraSvcProvider)));

// ── Notifier ───────────────────────────────────────────────────────
class MitraProfileNotifier
    extends StateNotifier<AsyncValue<MitraProfileModel>> {
  final MitraProfileRepository _repository;

  MitraProfileNotifier(this._repository) : super(const AsyncLoading()) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) loadProfile(uid);
  }

  Future<void> loadProfile(String uid) async {
    state = const AsyncLoading();
    try {
      final profile = await _repository.getProfile(uid);
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
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
      await _repository.updateProfile(updated);
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
      await _repository.updateProfile(updated);
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
      await _repository.updateNotificationSettings(
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
      await _repository.updateNotificationSettings(
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
      final url = await _repository.uploadLogo(current.id, image);
      final updated = current.copyWith(logoUrl: url);
      await _repository.updateProfile(updated);
      state = AsyncData(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadDocument(String docType, File file) async {
    if (state is! AsyncData) return;
    final current = state.value!;
    try {
      final url = await _repository.uploadDocument(current.id, docType, file);
      MitraProfileModel updated;
      if (docType.toLowerCase() == 'ktp') {
        updated = current.copyWith(ktpUrl: url);
      } else {
        updated = current.copyWith(npwpUrl: url);
      }
      await _repository.updateProfile(updated);
      state = AsyncData(updated);
    } catch (e) {
      rethrow;
    }
  }
}

final MitraProfileProvider = StateNotifierProvider<MitraProfileNotifier,
    AsyncValue<MitraProfileModel>>((ref) {
  final repo = ref.watch(MitraProfileRepositoryProvider);
  return MitraProfileNotifier(repo);
});
