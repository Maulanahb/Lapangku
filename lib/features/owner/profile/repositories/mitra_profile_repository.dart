import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapangku/features/Mitra/profile/models/Mitra_profile_model.dart';
import 'package:lapangku/services/firebase/Mitra_service.dart';

class MitraProfileRepository {
  final MitraService _service;

  MitraProfileRepository(this._service);

  Future<MitraProfileModel> getProfile(String uid) => _service.getProfile(uid);

  Future<void> updateProfile(MitraProfileModel profile) =>
      _service.updateProfile(profile);

  Future<void> createProfile(MitraProfileModel profile) =>
      _service.createProfile(profile);

  Future<void> updateNotificationSettings(
    String uid, {
    required bool orderNotif,
    required bool promoNotif,
  }) =>
      _service.updateNotificationSettings(uid,
          orderNotif: orderNotif, promoNotif: promoNotif);

  Future<String> uploadLogo(String uid, File file) =>
      _service.uploadLogo(uid, file);

  Future<String> uploadDocument(String uid, String docType, File file) =>
      _service.uploadDocument(uid, docType, file);

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
}
