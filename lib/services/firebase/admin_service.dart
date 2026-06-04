import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/models/admin/admin_field_model.dart';
import 'package:lapangku/models/admin/booking_model.dart';
import 'package:lapangku/models/admin/admin_stats.dart';
import 'package:lapangku/models/booking/booking_model.dart' as global_booking;

class AdminService {
  final FirebaseFirestore _firestore = FirestoreService.instance;

  Future<AdminStats> getStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 1. Total users (role: customer) count
    final usersCountSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .count()
        .get();
    final totalUsers = usersCountSnap.count ?? 0;

    // 2. Lapangan aktif (mitra collection count)
    final mitraCountSnap = await _firestore.collection('mitra').count().get();
    final lapanganAktif = mitraCountSnap.count ?? 0;

    // 3. Pesanan hari ini
    final todayBookingsSnap = await _firestore
        .collection('bookings')
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
        .count()
        .get();
    final pesananHariIni = todayBookingsSnap.count ?? 0;

    // 4. Total Pendapatan — dihitung langsung dari booking berstatus 'selesai'
    int totalPendapatan = 0;
    try {
      final selesaiSnap = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'selesai')
          .get();
      for (final doc in selesaiSnap.docs) {
        final data = doc.data();
        totalPendapatan += (data['totalBayar'] ?? data['totalHarga'] ?? 0) as int;
      }
    } catch (_) {
      // Gagal hitung, tetap gunakan 0
    }

    // 5. Booking Status Counts for Donut Chart (Apply client-side auto-expire logic by parsing them via BookingModel)
    final allBookingsSnap = await _firestore.collection('bookings').get();
    int countSelesai = 0;
    int countMenungguBayar = 0;
    int countMenungguKonfirmasi = 0;
    int countDikonfirmasi = 0;
    int countDibatalkan = 0;

    for (var doc in allBookingsSnap.docs) {
      // Use global_booking.BookingModel to apply the exact same logic (auto-expire, fallbacks) used in the UI
      final booking = global_booking.BookingModel.fromFirestore(doc);
      switch (booking.status) {
        case 'selesai':
          countSelesai++;
          break;
        case 'menunggu_bayar':
          countMenungguBayar++;
          break;
        case 'menunggu_konfirmasi':
          countMenungguKonfirmasi++;
          break;
        case 'dikonfirmasi':
          countDikonfirmasi++;
          break;
        case 'dibatalkan':
        case 'ditolak':
        case 'expired':
          countDibatalkan++;
          break;
      }
    }

    return AdminStats(
      totalUsers: totalUsers,
      lapanganAktif: lapanganAktif,
      pesananHariIni: pesananHariIni,
      totalPendapatan: totalPendapatan,
      countSelesai: countSelesai,
      countMenungguBayar: countMenungguBayar,
      countMenungguKonfirmasi: countMenungguKonfirmasi,
      countDikonfirmasi: countDikonfirmasi,
      countDibatalkan: countDibatalkan,
    );
  }

  /// Retrieves a page of users with optional pagination.
  ///
  /// [limit] defines the maximum number of documents returned (default 20).
  /// [startAfter] should be the last document snapshot from the previous page
  ///   (obtained from a previous query) to continue fetching.
  Future<List<Map<String, dynamic>>> getUsersPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection('users').limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => <String, dynamic>{'uid': d.id, ...(d.data()! as Map<String, dynamic>)})
        .toList();
  }

  // Backward compatible method (returns all users, may be heavy).
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs
        .map((d) => <String, dynamic>{'uid': d.id, ...d.data()})
        .toList();
  }

  /// Alias for updateUserStatus — used by AllUsersNotifier.
  Future<void> updateUserVerifikasi(String uid, String status) async {
    await updateUserStatus(uid, status);
  }

  Future<List<AdminFieldModel>> getAllFields() async {
    try {
      final snap = await _firestore.collection('mitra').get();
      return snap.docs.map((d) {
        final data = d.data();
        
        String status = (data['statusVerifikasi'] ?? 'menunggu').toString().toLowerCase().trim();
        if (!data.containsKey('statusVerifikasi')) {
          status = (data['isVerified'] == true) ? 'aktif' : 'menunggu';
        }

        return AdminFieldModel(
          fieldId: d.id,
          mitraId: d.id,
          namaLapangan: data['namaLapangan'] ?? data['businessName'] ?? data['namaBisnis'] ?? 'Bisnis Baru',
          namaMitra: data['ownerName'] ?? data['mitraName'] ?? data['nama'] ?? 'Mitra',
          emailPemilik: data['email'] ?? 'mitra@example.com',
          lokasi: data['alamat'] ?? 'Alamat belum diatur',
          hargaPerJam: data['hargaPerJam'] ?? 0,
          jenis: data['sport'] ?? 'Semua Lapangan',
          statusVerifikasi: status,
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getAllFields: $e');
      return [];
    }
  }

  /// Retrieves bookings with pagination (limit 20)
  Future<List<BookingModel>> getAllBookings({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection('bookings').limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    return snap.docs.map((d) {
      final data = d.data()! as Map<String, dynamic>;
      return BookingModel(
        bookingId: d.id,
        namaLapangan: data['fieldName'] ?? data['namaLapangan'] ?? '',
        namaPenyewa: data['userName'] ?? data['namaPenyewa'] ?? '',
        tanggal: (data['tanggal'] as Timestamp).toDate(),
        jamMulai: data['jamMulai'] ?? '',
        jamSelesai: data['jamSelesai'] ?? '',
        totalHarga: (data['totalBayar'] ?? data['totalHarga'] ?? 0) as int,
        status: data['status'] ?? 'menunggu',
      );
    }).toList();
  }

  /// Retrieves users with pagination (limit 20)
  Future<List<Map<String, dynamic>>> getAllUsersPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection('users').limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => <String, dynamic>{'uid': d.id, ...(d.data()! as Map<String, dynamic>)})
        .toList();
  }


  // Existing methods remain unchanged
  Future<void> updateUserStatus(String uid, String status) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'statusVerifikasi': status});
  }

  Future<void> addUser(Map<String, dynamic> data) async {
    final password = data['password'] as String?;
    data.remove('password'); // jangan simpan password ke Firestore

    if (password != null && password.isNotEmpty) {
      // Gunakan secondary Firebase App agar sesi super admin tidak terganggu
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = await Firebase.initializeApp(
          name: 'secondaryApp',
          options: Firebase.app().options,
        );
      } catch (_) {
        // Sudah ada secondary app (misal dari sebelumnya), gunakan yang ada
        secondaryApp = Firebase.app('secondaryApp');
      }

      try {
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: data['email'] as String,
          password: password,
        );
        final uid = credential.user!.uid;
        // Sign out dari secondary agar bersih
        await secondaryAuth.signOut();

        data['uid'] = uid;
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(uid).set(data);
      } finally {
        await secondaryApp.delete();
      }
    } else {
      // Fallback: hanya simpan ke Firestore (tanpa Auth)
      final docRef = _firestore.collection('users').doc();
      data['uid'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      await docRef.set(data);
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    // Also try to delete from mitra if it exists
    try {
      await _firestore.collection('mitra').doc(uid).delete();
    } catch (_) {}
  }

  Future<void> updateFieldVerifikasi({
    required String fieldId,
    required String mitraId,
    required String status,
  }) async {
    final batch = _firestore.batch();
    final isVerified = status == 'aktif';

    // Update the mitra collection
    batch.update(
      _firestore.collection('mitra').doc(mitraId),
      {
        'statusVerifikasi': status,
        'isVerified': isVerified,
      },
    );
    
    // Update the users collection
    batch.update(
      _firestore.collection('users').doc(mitraId),
      {
        'statusVerifikasi': status,
        'isVerified': isVerified,
      },
    );
    
    await batch.commit();
  }

  /// Ambil jumlah booking 7 hari terakhir (Sen-Min)
  Future<List<int>> getBookingsPerHari() async {
    final now = DateTime.now();
    final hasil = <int>[];

    for (int i = 6; i >= 0; i--) {
      final hari = now.subtract(Duration(days: i));
      final start = DateTime(hari.year, hari.month, hari.day);
      final end = start.add(const Duration(days: 1));

      final snap = await _firestore
          .collection('bookings')
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('tanggal', isLessThan: Timestamp.fromDate(end))
          .count()
          .get();

      hasil.add(snap.count ?? 0);
    }
    return hasil;
  }

  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final results = await Future.wait([
        _firestore
            .collection('bookings')
            .orderBy('tanggal', descending: true)
            .limit(10)
            .get(),
        _firestore
            .collection('mitra')
            .limit(20)
            .get(),
      ]);

      final List<Map<String, dynamic>> activities = [];

      // Bookings
      final bookingsSnap = results[0] as QuerySnapshot;
      for (var doc in bookingsSnap.docs) {
        final booking = global_booking.BookingModel.fromFirestore(doc);
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final dynamic t = data['tanggal'];
        DateTime time = DateTime.now();
        if (t is Timestamp) {
          time = t.toDate();
        }

        activities.add({
          'time': time,
          'user': booking.userName.isNotEmpty ? booking.userName : 'Penyewa',
          'action': 'New Booking',
          'detail': booking.fieldName.isNotEmpty ? booking.fieldName : 'Tanpa Keterangan',
          'status': booking.status,
          'type': 'booking',
        });
      }

      // New Owners (Mitra)
      final ownersSnap = results[1] as QuerySnapshot;
      for (var doc in ownersSnap.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final dynamic t = data['createdAt'];
        DateTime time = DateTime.now().subtract(const Duration(days: 365)); // Default old
        
        if (t is Timestamp) {
          time = t.toDate();
        } else if (data['isVerified'] == false) {
          // Jika belum verifikasi dan gapunya createdAt, anggap baru
          time = DateTime.now();
        }

        activities.add({
          'time': time,
          'user': data['ownerName'] ?? data['businessName'] ?? 'Pemilik Baru',
          'action': 'Pendaftaran Pemilik',
          'detail': data['businessName'] ?? '',
          'status': data['statusVerifikasi'] ?? 'menunggu',
          'type': 'registration',
        });
      }

      // Sort by time (Newest first)
      activities.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      return activities.take(10).toList();
    } catch (e) {
      debugPrint('Error getRecentActivities: $e');
      return [];
    }
  }

  // ————————————————————————————————————————————————————————————————————————————————
  // PAYOUTS
  // ————————————————————————————————————————————————————————————————————————————————

  Stream<List<Map<String, dynamic>>> streamAllPayouts() {
    return _firestore
        .collection('payouts')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Future<void> updatePayoutStatus({
    required String payoutId,
    required String status,
    String? proofUrl,
    String? notes,
  }) async {
    final Map<String, dynamic> data = {
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
    };
    if (proofUrl != null) data['proofUrl'] = proofUrl;
    if (notes != null) data['notes'] = notes;

    await _firestore.collection('payouts').doc(payoutId).update(data);
  }
}

