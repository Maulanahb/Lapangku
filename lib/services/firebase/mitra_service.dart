import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/models/mitra/mitra_schedule_model.dart';
import 'package:lapangku/models/mitra/mitra_revenue_model.dart';
import 'package:lapangku/models/mitra/mitra_review_model.dart';
import 'package:lapangku/models/mitra/mitra_payout_model.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase_storage_service.dart';
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
    return await FirebaseStorageService.uploadMultipleImages(photos, folder: 'fields');
  }

  Future<String> uploadLogo(String uid, File imageFile) async {
    if (!await imageFile.exists()) throw Exception('File logo tidak ditemukan');
    final url = await FirebaseStorageService.uploadImage(imageFile, folder: 'logos');
    return url!;
  }

  Future<String> uploadDocument(String uid, String docType, File file) async {
    if (!await file.exists()) throw Exception('File dokumen tidak ditemukan');
    final url = await FirebaseStorageService.uploadImage(file, folder: 'documents');
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

    // Filter langsung di Firestore (server-side) menggunakan mitraId dan rentang tanggal.
    // Menghindari mendownload SEMUA riwayat booking mitra sejak awal dibuat.
    final snap = await _db
        .collection('bookings')
        .where('mitraId', isEqualTo: MitraId)
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final allBookings = snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();

    final validBookings = allBookings.where((b) {
      return b.status == 'dikonfirmasi' || b.status == 'selesai';
    }).toList();

    int totalRevenue = 0;
    int todayRevenue = 0;
    int activeBookings = 0;
    List<MitraTransactionModel> transactions = [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var b in validBookings) {
      if (b.status == 'selesai') {
        // Mitra's revenue is hargaLapangan (totalBayar - biayaLayanan)
        totalRevenue += b.hargaLapangan;
        
        // Cek jika transaksi hari ini
        if (b.tanggal.year == today.year && 
            b.tanggal.month == today.month && 
            b.tanggal.day == today.day) {
          todayRevenue += b.hargaLapangan;
        }

        transactions.add(MitraTransactionModel(
          id: b.id,
          customerName: b.userName,
          fieldName: b.fieldName,
          amount: b.hargaLapangan,
          date: b.tanggal,
        ));
      } else if (b.status == 'dikonfirmasi') {
        activeBookings++;
      }
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    // Fetch Payouts untuk menghitung balance sesungguhnya
    int pendingPayout = 0;
    int disbursedRevenue = 0;

    final payoutsSnap = await _db
        .collection('payouts')
        .where('mitraId', isEqualTo: MitraId)
        .get();

    for (var doc in payoutsSnap.docs) {
      final payout = MitraPayoutModel.fromFirestore(doc);
      if (payout.status == 'pending' || payout.status == 'processing') {
        pendingPayout += payout.amount;
      } else if (payout.status == 'completed') {
        disbursedRevenue += payout.amount;
      }
    }

    // Saldo Aktif = Total Pendapatan Selesai - Pendapatan Cair - Pendapatan Sedang Proses
    final availableBalance = totalRevenue - disbursedRevenue - pendingPayout;

    return MitraRevenueModel(
      totalRevenue: totalRevenue,
      totalOrders: transactions.length,
      transactions: transactions,
      todayRevenue: todayRevenue,
      pendingPayout: pendingPayout,
      disbursedRevenue: disbursedRevenue,
      availableBalance: availableBalance > 0 ? availableBalance : 0,
      activeBookings: activeBookings,
      payoutSuccessRate: payoutsSnap.docs.isEmpty ? 1.0 : (payoutsSnap.docs.where((d) => d.data()['status'] == 'completed').length / payoutsSnap.docs.length),
    );
  }

  Future<List<MitraReviewModel>> getReviews(String mitraId) async {
    final querySnapshot = await _db
        .collectionGroup('reviews')
        .where('mitraId', isEqualTo: mitraId)
        .get();

    final reviews = querySnapshot.docs
        .map((doc) => MitraReviewModel.fromFirestore(doc))
        .toList();

    // Sort locally descending by date
    reviews.sort((a, b) => b.date.compareTo(a.date));

    return reviews;
  }

  Future<void> replyReview({
    required String fieldId,
    required String reviewId,
    required String replyText,
  }) async {
    await _db
        .collection('lapangan')
        .doc(fieldId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'replyText': replyText,
      'replyDate': FieldValue.serverTimestamp(),
    });
  }

  // ————————————————————————————————————————————————————————————————————————————————
  // PAYOUTS
  // ————————————————————————————————————————————————————————————————————————————————

  Future<void> requestPayout(MitraPayoutModel payout) async {
    final docRef = _db.collection('payouts').doc();
    final newPayout = payout.copyWith(id: docRef.id);
    await docRef.set(newPayout.toFirestore());
  }

  Stream<List<MitraPayoutModel>> streamMitraPayouts(String mitraId) {
    return _db
        .collection('payouts')
        .where('mitraId', isEqualTo: mitraId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MitraPayoutModel.fromFirestore(d)).toList());
  }
}
