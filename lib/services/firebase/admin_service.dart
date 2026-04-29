import 'package:cloud_firestore/cloud_firestore.dart';
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
      _firestore.collection('users').where('role', isEqualTo: 'mitra').get(),
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
        return total + ((data['totalHarga'] ?? 0) as int);
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
    final snap = await _firestore.collection('owners').get();
    return snap.docs.map((d) {
      final data = d.data();
      // Map isVerified to statusVerifikasi if statusVerifikasi is not present
      String status = data['statusVerifikasi'] ?? 'menunggu';
      if (!data.containsKey('statusVerifikasi')) {
        status = (data['isVerified'] == true) ? 'aktif' : 'menunggu';
      }

      return AdminFieldModel(
        fieldId: d.id, // Using owner UID as fieldId since we verify owners
        ownerUid: d.id,
        namaLapangan: data['businessName'] ?? data['namaBisnis'] ?? 'Bisnis Baru',
        namaMitra: data['ownerName'] ?? data['nama'] ?? 'Owner',
        emailPemilik: data['email'] ?? 'mitra@example.com',
        lokasi: data['alamat'] ?? 'Alamat belum diatur',
        hargaPerJam: 0,
        jenis: 'Semua Lapangan',
        statusVerifikasi: status,
        createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now().subtract(const Duration(days: 2)),
      );
    }).toList();
  }

  Future<List<BookingModel>> getAllBookings() async {
    final snap = await _firestore
        .collection('bookings')
        .orderBy('tanggal', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return BookingModel(
        bookingId: d.id,
        namaLapangan: data['namaLapangan'] ?? '',
        namaPenyewa: data['namaPenyewa'] ?? '',
        tanggal: (data['tanggal'] as Timestamp).toDate(),
        jamMulai: data['jamMulai'] ?? '',
        jamSelesai: data['jamSelesai'] ?? '',
        totalHarga: (data['totalHarga'] ?? 0) as int,
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

  Future<void> updateFieldVerifikasi({
    required String fieldId,
    required String ownerUid,
    required String status,
  }) async {
    final batch = _firestore.batch();
    final isVerified = status == 'aktif';

    // Update the owners collection
    batch.update(
      _firestore.collection('owners').doc(ownerUid),
      {
        'statusVerifikasi': status,
        'isVerified': isVerified,
      },
    );
    
    // Update the users collection
    batch.update(
      _firestore.collection('users').doc(ownerUid),
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
}
