import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lapangku/features/Mitra/field/models/Mitra_field_model.dart';
import 'package:lapangku/features/Mitra/profile/models/Mitra_profile_model.dart';
import 'package:lapangku/features/Mitra/schedule/models/Mitra_schedule_model.dart';

class MitraService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────

  Future<MitraProfileModel> getProfile(String uid) async {
    final doc = await _db.collection('Mitras').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return MitraProfileModel.empty(uid);
    }
    return MitraProfileModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> createProfile(MitraProfileModel profile) async {
    await _db.collection('Mitras').doc(profile.id).set(profile.toMap());
  }

  Future<void> updateProfile(MitraProfileModel profile) async {
    await _db
        .collection('Mitras')
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateNotificationSettings(
    String uid, {
    required bool orderNotif,
    required bool promoNotif,
  }) async {
    await _db.collection('Mitras').doc(uid).update({
      'notificationOrder': orderNotif,
      'notificationPromo': promoNotif,
    });
  }

  Future<String> uploadLogo(String uid, File imageFile) async {
    final ref = _storage.ref().child('Mitra_logos/$uid.jpg');
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadDocument(
      String uid, String docType, File file) async {
    final ext = file.path.split('.').last;
    final ref =
        _storage.ref().child('Mitra_documents/$uid/${docType}_${DateTime.now().millisecondsSinceEpoch}.$ext');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  // ─────────────────────────────────────────────
  // FIELDS
  // ─────────────────────────────────────────────

  Future<List<MitraFieldModel>> getMitraFields(String MitraId) async {
    final snap = await _db
        .collection('fields')
        .where('MitraId', isEqualTo: MitraId)
        .get();
    return snap.docs
        .map((d) => MitraFieldModel.fromMap(d.data(), d.id))
        .toList();
  }

  Stream<List<MitraFieldModel>> streamMitraFields(String MitraId) {
    return _db
        .collection('fields')
        .where('MitraId', isEqualTo: MitraId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MitraFieldModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<String> addField(
    MitraFieldModel field, {
    List<File>? photoFiles,
  }) async {
    final docRef = _db.collection('fields').doc();
    final List<String> photoUrls = await _uploadFieldPhotos(
      docRef.id,
      photoFiles ?? [],
    );
    final data = field.copyWith(id: docRef.id, photoUrls: photoUrls).toMap();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateField(
    MitraFieldModel field, {
    List<File>? newPhotoFiles,
  }) async {
    List<String> photoUrls = List.from(field.photoUrls);
    if (newPhotoFiles != null && newPhotoFiles.isNotEmpty) {
      final uploaded = await _uploadFieldPhotos(field.id, newPhotoFiles,
          suffix: 'new_${DateTime.now().millisecondsSinceEpoch}');
      photoUrls.addAll(uploaded);
    }
    await _db
        .collection('fields')
        .doc(field.id)
        .update(field.copyWith(photoUrls: photoUrls).toMap());
  }

  Future<void> deleteField(String fieldId) async {
    await _db.collection('fields').doc(fieldId).delete();
  }

  Future<void> toggleFieldStatus(String fieldId, bool isActive) async {
    await _db
        .collection('fields')
        .doc(fieldId)
        .update({'isActive': isActive});
  }

  Future<List<String>> _uploadFieldPhotos(
    String fieldId,
    List<File> photos, {
    String suffix = '',
  }) async {
    final urls = <String>[];
    for (int i = 0; i < photos.length; i++) {
      final name = suffix.isEmpty ? '${fieldId}_$i' : '${fieldId}_${suffix}_$i';
      final ref = _storage.ref().child('field_photos/$name.jpg');
      final task = await ref.putFile(photos[i]);
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  // ─────────────────────────────────────────────
  // SCHEDULES
  // ─────────────────────────────────────────────

  Future<List<MitraScheduleModel>> getSchedule(String fieldId) async {
    final snap = await _db
        .collection('schedules')
        .where('fieldId', isEqualTo: fieldId)
        .get();
    if (snap.docs.isEmpty) {
      return _defaultSchedule(fieldId);
    }
    return snap.docs
        .map((d) => MitraScheduleModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> saveSchedule(
      String fieldId, List<MitraScheduleModel> schedules) async {
    final batch = _db.batch();

    // Hapus jadwal lama
    final existing = await _db
        .collection('schedules')
        .where('fieldId', isEqualTo: fieldId)
        .get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Tulis jadwal baru
    for (final s in schedules) {
      final ref = _db.collection('schedules').doc();
      batch.set(ref, s.copyWith(id: ref.id, fieldId: fieldId).toMap());
    }

    await batch.commit();
  }

  static List<MitraScheduleModel> _defaultSchedule(String fieldId) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return days
        .map((day) => MitraScheduleModel(
              id: '',
              fieldId: fieldId,
              hari: day,
              jamBuka: '08:00',
              jamTutup: '22:00',
              isActive: true,
            ))
        .toList();
  }
}
