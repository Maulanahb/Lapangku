import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/models/mitra/mitra_schedule_model.dart';
import 'package:lapangku/models/mitra/mitra_revenue_model.dart';
import 'package:lapangku/models/mitra/mitra_review_model.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/cloudinary_service.dart';
import 'package:lapangku/standards/constants/app_constants.dart';

class MitraService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'lapangku-db',
  );
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

  Future<List<String>> uploadFieldPhotos(
    String fieldId,
    List<File> photos, {
    String suffix = '',
  }) async {
    return await CloudinaryService.uploadMultipleImages(photos);
  }

  Future<String> uploadLogo(String uid, File imageFile) async {
    if (!await imageFile.exists()) throw Exception('File logo tidak ditemukan');
    final url = await CloudinaryService.uploadImage(imageFile);
    return url!;
  }

  Future<String> uploadDocument(String uid, String docType, File file) async {
    if (!await file.exists()) throw Exception('File dokumen tidak ditemukan');
    final url = await CloudinaryService.uploadImage(file);
    return url!;
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

  // ————————————————————————————————————————————————————————————————————————————————
  // FIELDS
  // ————————————————————————————————————————————————————————————————————————————————

  Future<List<MitraFieldModel>> getMitraFields(String MitraId) async {
    final List<MitraFieldModel> allFields = [];
    print('=========================================');
    print('🔎 LOAD DATA UNTUK UID: $MitraId');

    try {
      // Query dari koleksi 'lapangan' — satu-satunya sumber data
      final snap = await _db
          .collection('lapangan')
          .where('MitraId', isEqualTo: MitraId)
          .get(const GetOptions(source: Source.server));

      print('📂 Koleksi "lapangan": Ditemukan ${snap.docs.length} dokumen');
      
      for (var doc in snap.docs) {
        final data = doc.data();
        final model = MitraFieldModel.fromMap(data, doc.id);
        allFields.add(model);
        print('   ✅ Lapangan: ${model.namaLapangan} | ID Doc: ${doc.id} | MitraId: ${data['MitraId']}');
      }
    } catch (e) {
      print('⚠️ ERROR LOAD: $e');
    }

    print('📊 HASIL AKHIR: ${allFields.length} Lapangan');
    print('=========================================');
    return allFields;
  }

  Stream<List<MitraFieldModel>> streamMitraFields(String MitraId) {
    return _db
        .collection('lapangan')
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
    final docRef = _db.collection('lapangan').doc();
    final initialData = field.copyWith(id: docRef.id, photoUrls: []).toMap();
    await docRef.set(initialData);

    if (photoFiles != null && photoFiles.isNotEmpty) {
      try {
        print('UPLOADING ${photoFiles.length} PHOTOS for new field...');
        final List<String> photoUrls = await uploadFieldPhotos(
          docRef.id,
          photoFiles,
        );
        print('UPLOAD SUCCESS. URLs: $photoUrls');

        await docRef.update({
          'photoUrls': photoUrls,
          'foto_lapangan': photoUrls, // ✅ Key yang dibaca Customer
        });
        print('FIRESTORE UPDATE SUCCESS');
        return docRef.id;
      } catch (e) {
        print('UPLOAD/UPDATE ERROR: $e');
        return docRef.id;
      }
    }
    return docRef.id;
  }

  Future<void> updateField(
    MitraFieldModel field, {
    List<File>? newPhotoFiles,
  }) async {
    print('=========================================');
    print('AKSI: UPDATE LAPANGAN ${field.namaLapangan}');
    print('ID: ${field.id}');
    print('FOTO BARU: ${newPhotoFiles?.length ?? 0}');
    print('=========================================');

    List<String> photoUrls = List.from(field.photoUrls);

    if (newPhotoFiles != null && newPhotoFiles.isNotEmpty) {
      print('Uploading ${newPhotoFiles.length} new photos...');
      final uploaded = await uploadFieldPhotos(field.id, newPhotoFiles,
          suffix: 'new_${DateTime.now().millisecondsSinceEpoch}');
      photoUrls.addAll(uploaded);
      print('Total photos after upload: ${photoUrls.length}');
    }

    final data = field.copyWith(photoUrls: photoUrls).toMap();
    // toMap() sudah menulis 'foto_lapangan' dan 'photoUrls'
    // Pastikan kedua key foto konsisten
    data['photoUrls'] = photoUrls;
    data['foto_lapangan'] = photoUrls;

    print('FINAL DATA TO SAVE: $data');

    final fieldRef = _db.collection('lapangan').doc(field.id);
    final fieldDoc = await fieldRef.get();

    if (fieldDoc.exists) {
      print('Updating in "lapangan" collection...');
      await fieldRef.update(data);
    } else {
      print('Document not found. Creating new in "lapangan"...');
      await fieldRef.set(data);
    }
    print('UPDATE COMPLETED SUCCESSFULLY');
  }

  Future<void> deleteField(String fieldId) async {
    await _db.collection('lapangan').doc(fieldId).delete();
  }

  Future<void> toggleFieldStatus(String fieldId, bool isActive) async {
    await _db
        .collection('lapangan')
        .doc(fieldId)
        .update({'is_aktif': isActive});
  }

  // ————————————————————————————————————————————————————————————————————————————————
  // SCHEDULES
  // ————————————————————————————————————————————————————————————————————————————————

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

    final existing = await _db
        .collection('schedules')
        .where('fieldId', isEqualTo: fieldId)
        .get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final s in schedules) {
      final ref = _db.collection('schedules').doc();
      batch.set(ref, s.copyWith(id: ref.id, fieldId: fieldId).toMap());
    }

    await batch.commit();
  }

  static List<MitraScheduleModel> _defaultSchedule(String fieldId) {
    // dayOfWeek: 1=Senin, 2=Selasa, ..., 7=Minggu
    return List.generate(7, (index) => MitraScheduleModel(
      id: '',
      fieldId: fieldId,
      dayOfWeek: index + 1,
      jamBuka: '08:00',
      jamTutup: '22:00',
      isActive: true,
    ));
  }

  // ————————————————————————————————————————————————————————————————————————————————
  // REVENUE & REVIEWS
  // ————————————————————————————————————————————————————————————————————————————————

  Future<MitraRevenueModel> getRevenue(
      String MitraId, DateTime startDate, DateTime endDate) async {
    final fields = await getMitraFields(MitraId);
    if (fields.isEmpty) {
      return const MitraRevenueModel(
          totalRevenue: 0, totalOrders: 0, transactions: []);
    }

    final fieldIds = fields.map((e) => e.id).toList();

    List<BookingModel> allBookings = [];

    for (int i = 0; i < fieldIds.length; i += AppConstants.firestoreWhereInLimit) {
      final chunk = fieldIds.sublist(
          i, i + AppConstants.firestoreWhereInLimit > fieldIds.length ? fieldIds.length : i + AppConstants.firestoreWhereInLimit);
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
