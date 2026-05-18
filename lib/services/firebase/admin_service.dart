import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/models/admin/admin_field_model.dart';
import 'package:lapangku/models/admin/booking_model.dart';
import 'package:lapangku/models/admin/admin_stats.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirestoreService.instance;

  Future<AdminStats> getStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await Future.wait([
      _firestore.collection('users').where('role', isEqualTo: 'customer').get(),
      _firestore.collection('mitra').get(),
      _firestore
          .collection('bookings')
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
          .get(),
      _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'selesai')
          .get(),
    ]);

    final totalPendapatan = (results[3] as QuerySnapshot).docs.fold<int>(
      0,
      (total, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return total + ((data['totalBayar'] ?? data['totalHarga'] ?? 0) as int);
      },
    );

    return AdminStats(
      totalUsers: results[0].size,
      lapanganAktif: results[1].size,
      pesananHariIni: results[2].size,
      totalPendapatan: totalPendapatan,
    );
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
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

  Future<List<BookingModel>> getAllBookings() async {
    final snap = await _firestore
        .collection('bookings')
        .orderBy('tanggal', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      
      String jamMulai = data['jamMulai'] ?? '';
      String jamSelesai = data['jamSelesai'] ?? '';
      
      if (data['timeSlots'] != null && (data['timeSlots'] as List).isNotEmpty) {
        final slots = List<String>.from(data['timeSlots']);
        try {
          jamMulai = slots.first.split(' - ').first.trim();
          jamSelesai = slots.last.split(' - ').last.trim();
        } catch (e) {
          jamMulai = slots.first;
          jamSelesai = slots.last;
        }
      }

      return BookingModel(
        bookingId: d.id,
        namaLapangan: data['fieldName'] ?? data['namaLapangan'] ?? '',
        namaPenyewa: data['userName'] ?? data['namaPenyewa'] ?? '',
        tanggal: (data['tanggal'] as Timestamp).toDate(),
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        totalHarga: (data['totalBayar'] ?? data['totalHarga'] ?? 0) as int,
        status: data['status'] ?? 'menunggu',
      );
    }).toList();
  }

  Future<void> updateUserVerifikasi(String uid, String status) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'statusVerifikasi': status});
  }

  Future<void> addUser(Map<String, dynamic> data) async {
    final docRef = _firestore.collection('users').doc();
    data['uid'] = docRef.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['isVerified'] = data['role'] == 'mitra' ? false : true;
    await docRef.set(data);
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
          .get();

      hasil.add(snap.size);
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
        final data = doc.data() as Map<String, dynamic>;
        final dynamic t = data['tanggal'];
        DateTime time = DateTime.now();
        if (t is Timestamp) {
          time = t.toDate();
        }

        activities.add({
          'time': time,
          'user': data['userName'] ?? data['namaPenyewa'] ?? 'Penyewa',
          'action': 'New Booking',
          'detail': data['fieldName'] ?? data['namaLapangan'] ?? '',
          'status': data['status'] ?? 'menunggu',
          'type': 'booking',
        });
      }

      // New Owners (Mitra)
      final ownersSnap = results[1] as QuerySnapshot;
      for (var doc in ownersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
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

