import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
    if (photos.isEmpty) return [];

    final sfx = suffix.isNotEmpty
        ? suffix
        : DateTime.now().millisecondsSinceEpoch.toString();
    if (kDebugMode) {
      debugPrint(
          'Mengunggah ${photos.length} foto secara paralel ke folder fields/$fieldId/...');
    }

    try {
      // 🌟 BYPASS & OPTIMASI PARALEL: Gambar langsung diupload bersamaan dalam satu waktu
      final List<Future<String>> uploadTasks =
          photos.asMap().entries.map((entry) async {
        final index = entry.key;
        final file = entry.value;

        if (!file.existsSync()) throw Exception('File tidak ditemukan');

        // 📁 STRUKTUR RAPI: Memaksa file masuk ke sub-folder ID lapangan, bukan root 'fields'
        final ref = _storage.ref().child('fields/$fieldId/${sfx}_$index.jpg');

        final uploadTask = await ref.putFile(file);
        return uploadTask.ref.getDownloadURL();
      }).toList();

      // Tunggu semua selesai barengan
      final List<String> completedUrls = await Future.wait(uploadTasks);
      if (kDebugMode) debugPrint('Upload Sukses! Semua URL didapatkan.');
      return completedUrls;
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR UPLOAD LAPANGAN: $e');
      throw Exception('Gagal upload foto lapangan: $e');
    }
  }

  Future<String> uploadLogo(String uid, File imageFile) async {
    if (!imageFile.existsSync()) throw Exception('File logo tidak ditemukan');
    final url =
        await FirebaseStorageService.uploadImage(imageFile, folder: 'logos');
    return url!;
  }

  Future<String> uploadDocument(String uid, String docType, File file) async {
    if (!file.existsSync()) throw Exception('File dokumen tidak ditemukan');
    final url =
        await FirebaseStorageService.uploadImage(file, folder: 'documents');
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
    if (kDebugMode) {
      debugPrint('=========================================');
      debugPrint('🔎 LOAD DATA UNTUK UID: $MitraId');
    }

    try {
      // Query dari koleksi 'lapangan' — satu-satunya sumber data
      final snap = await _db
          .collection('lapangan')
          .where('MitraId', isEqualTo: MitraId)
          .get();

      if (kDebugMode)
        debugPrint(
            '📂 Koleksi "lapangan": Ditemukan ${snap.docs.length} dokumen');

      for (var doc in snap.docs) {
        final data = doc.data();
        final model = MitraFieldModel.fromMap(data, doc.id);
        allFields.add(model);
        if (kDebugMode) {
          debugPrint(
              '   ✅ Lapangan: ${model.namaLapangan} | ID Doc: ${doc.id} | MitraId: ${data['MitraId']}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ERROR LOAD: $e');
    }

    if (kDebugMode) {
      debugPrint('📊 HASIL AKHIR: ${allFields.length} Lapangan');
      debugPrint('=========================================');
    }
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
    // 1. Buat referensi dokumen baru untuk mendapatkan ID unik terlebih dahulu
    final docRef = _db.collection('lapangan').doc();
    final initialData = field.copyWith(id: docRef.id, photoUrls: []).toMap();

    // 2. Tulis data awal ke Firestore
    await docRef.set(initialData);

    if (photoFiles != null && photoFiles.isNotEmpty) {
      try {
        if (kDebugMode)
          debugPrint('UPLOADING ${photoFiles.length} PHOTOS for new field...');
        final List<String> photoUrls = await uploadFieldPhotos(
          docRef.id,
          photoFiles,
        );
        if (kDebugMode) debugPrint('UPLOAD SUCCESS. URLs: $photoUrls');

        // 3. Update dokumen dengan URL foto yang berhasil di-upload
        await docRef.update({
          'photoUrls': photoUrls,
          'foto_lapangan': photoUrls, // ✅ Key yang dibaca Customer
        });
        if (kDebugMode) debugPrint('FIRESTORE UPDATE SUCCESS');
        return docRef.id;
      } catch (e) {
        if (kDebugMode) debugPrint('UPLOAD/UPDATE ERROR: $e');

        // 🚨 SAFETY FALLBACK: Jika upload foto gagal, hapus kembali dokumen Firestore
        // yang terlanjur dibuat di atas agar tidak menjadi data sampah/cacat di DB.
        try {
          await docRef.delete();
          if (kDebugMode) {
            debugPrint(
                'ROLLBACK SUCCESS: Dokumen cacat berhasil dihapus dari Firestore');
          }
        } catch (deleteError) {
          if (kDebugMode)
            debugPrint('FAILED TO ROLLBACK FIRESTORE: $deleteError');
        }

        // Lemparkan error ke provider agar UI tahu kalau ini GAGAL
        throw Exception(
            'Gagal mengunggah foto lapangan. Silakan coba lagi. ($e)');
      }
    }
    return docRef.id;
  }

  Future<void> updateField(
    MitraFieldModel field, {
    List<File>? newPhotoFiles,
  }) async {
    if (kDebugMode) {
      debugPrint('=========================================');
      debugPrint('AKSI: UPDATE LAPANGAN ${field.namaLapangan}');
      debugPrint('ID: ${field.id}');
      debugPrint('FOTO BARU: ${newPhotoFiles?.length ?? 0}');
      debugPrint('=========================================');
    }

    final fieldRef = _db.collection('lapangan').doc(field.id);
    final fieldDoc = await fieldRef.get();

    // 🚨 PROTECTION 1: Lacak dan bersihkan foto sampah di Storage jika dokumen sudah ada
    if (fieldDoc.exists) {
      final oldData = fieldDoc.data();
      if (oldData != null && oldData['photoUrls'] != null) {
        // Ambil daftar URL foto yang ada di database saat ini
        final List<dynamic> dbPhotos = oldData['photoUrls'];
        final List<Future<void>> deleteTasks = [];

        // Cari URL foto yang ada di DB tetapi sudah TIDAK ADA di object 'field' baru (artinya dihapus oleh user)
        for (var url in dbPhotos) {
          if (!field.photoUrls.contains(url)) {
            deleteTasks.add(() async {
              try {
                if (kDebugMode)
                  debugPrint('MENGHAPUS FOTO SAMPAH DARI STORAGE: $url');
                // Hapus file fisik dari Firebase Storage menggunakan URL-nya
                await _storage.refFromURL(url).delete();
                if (kDebugMode)
                  debugPrint('BERHASIL MENGHAPUS FOTO DARI STORAGE');
              } catch (storageError) {
                // Gunakan catch agar jika 1 foto gagal dihapus (misal karena sudah tidak ada), proses update tidak crash
                if (kDebugMode)
                  debugPrint(
                      'GAGAL MENGHAPUS FOTO DARI STORAGE: $storageError');
              }
            }());
          }
        }

        // Jalankan penghapusan di background agar tidak memblokir penyimpanan Firestore
        if (deleteTasks.isNotEmpty) {
          Future.wait(deleteTasks);
        }
      }
    }

    List<String> photoUrls = List.from(field.photoUrls);

    // 2. Upload foto baru jika ada
    if (newPhotoFiles != null && newPhotoFiles.isNotEmpty) {
      if (kDebugMode)
        debugPrint('Uploading ${newPhotoFiles.length} new photos...');
      final uploaded = await uploadFieldPhotos(
        field.id,
        newPhotoFiles,
        suffix: 'new_${DateTime.now().millisecondsSinceEpoch}',
      );
      photoUrls.addAll(uploaded);
      if (kDebugMode)
        debugPrint('Total photos after upload: ${photoUrls.length}');
    }

    final data = field.copyWith(photoUrls: photoUrls).toMap();
    // Pastikan kedua key foto konsisten
    data['photoUrls'] = photoUrls;
    data['foto_lapangan'] = photoUrls;

    if (kDebugMode) debugPrint('FINAL DATA TO SAVE: $data');

    // 3. Simpan perubahan ke Firestore
    if (fieldDoc.exists) {
      if (kDebugMode) debugPrint('Updating in "lapangan" collection...');
      await fieldRef.update(data);
    } else {
      if (kDebugMode)
        debugPrint('Document not found. Creating new in "lapangan"...');
      await fieldRef.set(data);
    }
    if (kDebugMode) debugPrint('UPDATE COMPLETED SUCCESSFULLY');
  }

  Future<void> deleteField(String fieldId) async {
    await _db.collection('lapangan').doc(fieldId).delete();
  }

  Future<void> toggleFieldStatus(String fieldId,
      {required bool isActive}) async {
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
    return List.generate(
        7,
        (index) => MitraScheduleModel(
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

    for (int i = 0;
        i < fieldIds.length;
        i += AppConstants.firestoreWhereInLimit) {
      final chunk = fieldIds.sublist(
          i,
          i + AppConstants.firestoreWhereInLimit > fieldIds.length
              ? fieldIds.length
              : i + AppConstants.firestoreWhereInLimit);
      final snap = await _db
          .collection('bookings')
          .where('fieldId', whereIn: chunk)
          .get();

      allBookings.addAll(snap.docs.map((d) => BookingModel.fromFirestore(d)));
    }

    final validBookings = allBookings.where((b) {
      return b.status == 'dikonfirmasi' || b.status == 'selesai';
    }).toList();

    int totalRevenue = 0;
    int todayRevenue = 0;
    int activeBookings = 0;
    int periodRevenue = 0;
    List<MitraTransactionModel> transactions = [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate previous period for growth
    final duration = endDate.difference(startDate);
    final previousPeriodStart = startDate.subtract(duration);
    final previousPeriodEnd = startDate;

    int currentPeriodRevenue = 0;
    int previousPeriodRevenue = 0;

    for (var b in validBookings) {
      if (b.status == 'selesai' || b.status == 'dikonfirmasi') {
        final revenueDate = b.tanggal;
        totalRevenue += b.hargaLapangan; // Menggunakan harga asli lapangan

        // Cek jika transaksi hari ini berdasarkan tanggal main.
        // Ini membuat booking yang di-reschedule masuk ke pendapatan tanggal baru.
        if (revenueDate.year == today.year &&
            revenueDate.month == today.month &&
            revenueDate.day == today.day) {
          todayRevenue += b.hargaLapangan;
        }

        final tx = MitraTransactionModel(
          id: b.id,
          customerName: b.userName,
          fieldName: b.fieldName,
          amount: b.hargaLapangan,
          date: revenueDate,
        );

        // Filter for current period
        if (revenueDate
                .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            revenueDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
          periodRevenue += b.hargaLapangan;
          transactions.add(tx);
          currentPeriodRevenue += b.hargaLapangan;
        }
        // Filter for previous period (for growth)
        else if (revenueDate.isAfter(
                previousPeriodStart.subtract(const Duration(seconds: 1))) &&
            revenueDate
                .isBefore(previousPeriodEnd.add(const Duration(seconds: 1)))) {
          previousPeriodRevenue += b.hargaLapangan;
        }
      }
      if (b.status == 'dikonfirmasi') {
        activeBookings++;
      }
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    double revenueGrowth = 0.0;
    if (previousPeriodRevenue > 0) {
      revenueGrowth = ((currentPeriodRevenue - previousPeriodRevenue) /
              previousPeriodRevenue) *
          100;
    } else if (currentPeriodRevenue > 0) {
      revenueGrowth = 100.0;
    }

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
      payoutSuccessRate: payoutsSnap.docs.isEmpty
          ? 1.0
          : (payoutsSnap.docs
                  .where((d) => d.data()['status'] == 'completed')
                  .length /
              payoutsSnap.docs.length),
      revenueGrowth: revenueGrowth,
      periodRevenue: periodRevenue,
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

  /// Stream realtime untuk semua review milik mitra.
  /// Digunakan oleh halaman Ulasan Pelanggan agar auto-update
  /// saat customer menambah, mengedit, atau menghapus review.
  Stream<List<MitraReviewModel>> streamReviews(String mitraId) {
    if (mitraId.isEmpty) return Stream.value([]);
    return _db
        .collectionGroup('reviews')
        .where('mitraId', isEqualTo: mitraId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => MitraReviewModel.fromFirestore(doc))
          .toList();
      // Sort locally descending by date
      reviews.sort((a, b) => b.date.compareTo(a.date));
      return reviews;
    });
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
      'isReplied': true,
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
