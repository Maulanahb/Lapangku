import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/models/mitra/mitra_schedule_model.dart';
import 'package:lapangku/models/mitra/mitra_revenue_model.dart';
import 'package:lapangku/models/mitra/mitra_review_model.dart';
import 'package:lapangku/models/booking/booking_model.dart';

class MitraService {
  final FirebaseFirestore _db = FirestoreService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // PROFILE
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Future<MitraProfileModel> getProfile(String uid) async {
    // Mencari di koleksi 'mitra' sesuai pendaftaran
    final doc = await _db.collection('mitra').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return MitraProfileModel.empty(uid);
    }
    return MitraProfileModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> createProfile(MitraProfileModel profile) async {
    await _db.collection('mitra').doc(profile.id).set(profile.toMap());
  }

  Future<void> updateProfile(MitraProfileModel profile) async {
    await _db
        .collection('mitra')
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateNotificationSettings(
    String uid, {
    required bool orderNotif,
    required bool promoNotif,
  }) async {
    await _db.collection('mitra').doc(uid).update({
      'notificationOrder': orderNotif,
      'notificationPromo': promoNotif,
    });
  }

  Future<String> uploadLogo(String uid, File imageFile) async {
    final ref = _storage.ref().child('mitra_logos/$uid.jpg');
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadDocument(String uid, String docType, File file) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref().child(
        'mitra_documents/$uid/${docType}_${DateTime.now().millisecondsSinceEpoch}.$ext');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // FIELDS
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Future<List<MitraFieldModel>> getMitraFields(String MitraId) async {
    // Pertama cari di koleksi 'fields'
    final snap = await _db
        .collection('fields')
        .where('MitraId', isEqualTo: MitraId)
        .get();

    if (snap.docs.isEmpty) {
      // Jika kosong, cek apakah data ada di koleksi 'mitra' (data dari pendaftaran awal)
      final mitraDoc = await _db.collection('mitra').doc(MitraId).get();
      if (mitraDoc.exists) {
        return [MitraFieldModel.fromMap(mitraDoc.data()!, mitraDoc.id)];
      }
    }

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
    await _db.collection('fields').doc(fieldId).update({'isActive': isActive});
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

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // SCHEDULES
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

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
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // REVENUE & REVIEWS (Refactored from Repositories)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<MitraRevenueModel> getRevenue(
      String MitraId, DateTime startDate, DateTime endDate) async {
    final fields = await getMitraFields(MitraId);
    if (fields.isEmpty) {
      return const MitraRevenueModel(
          totalRevenue: 0, totalOrders: 0, transactions: []);
    }

    final fieldIds = fields.map((e) => e.id).toList();

    List<BookingModel> allBookings = [];

    for (int i = 0; i < fieldIds.length; i += 30) {
      final chunk = fieldIds.sublist(
          i, i + 30 > fieldIds.length ? fieldIds.length : i + 30);
      final snap = await _db
          .collection('bookings')
          .where('fieldId', whereIn: chunk)
          .get();

      allBookings.addAll(snap.docs.map((d) => BookingModel.fromFirestore(d)));
    }

    final validBookings = allBookings.where((b) {
      final isDateValid =
          b.tanggal.isAfter(startDate.subtract(const Duration(days: 1))) &&
              b.tanggal.isBefore(endDate.add(const Duration(days: 1)));

      return isDateValid &&
          (b.status == 'dikonfirmasi' || b.status == 'selesai');
    }).toList();

    int totalRevenue = 0;
    List<MitraTransactionModel> transactions = [];

    for (var b in validBookings) {
      totalRevenue += b.totalBayar;
      transactions.add(MitraTransactionModel(
        id: b.id,
        customerName: b.userName,
        fieldName: b.fieldName,
        amount: b.totalBayar,
        date: b.tanggal,
      ));
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    return MitraRevenueModel(
      totalRevenue: totalRevenue,
      totalOrders: validBookings.length,
      transactions: transactions,
    );
  }

  Future<List<MitraReviewModel>> getReviews() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API
    return [
      MitraReviewModel(
          id: '1',
          userName: 'Andi S.',
          rating: 5,
          comment: 'Lapangan bagus dan bersih.',
          date: DateTime(2026, 10, 12)),
      MitraReviewModel(
          id: '2',
          userName: 'Budi P.',
          rating: 4,
          comment: 'Oke lah buat main bareng.',
          date: DateTime(2026, 10, 10)),
    ];
  }
}
