import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/field_entity.dart';
import '../../domain/entities/booking_entity.dart';

class AdminStats {
  final int totalUsers;
  final int lapanganAktif;
  final int pesananHariIni;
  final int totalPendapatan;

  const AdminStats({
    required this.totalUsers,
    required this.lapanganAktif,
    required this.pesananHariIni,
    required this.totalPendapatan,
  });
}

class AdminRemoteDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AdminStats> getStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await Future.wait([
      _firestore.collection('users').get(),
      _firestore
          .collection('fields')
          .where('statusVerifikasi', isEqualTo: 'aktif')
          .get(),
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
      (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return sum + ((data['totalHarga'] ?? 0) as int);
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

  Future<List<FieldEntity>> getAllFields() async {
    final snap = await _firestore.collection('fields').get();
    return snap.docs.map((d) {
      final data = d.data();
      return FieldEntity(
        fieldId: d.id,
        ownerUid: data['ownerUid'] ?? '',
        namaLapangan: data['namaLapangan'] ?? '',
        namaMitra: data['namaMitra'] ?? '',
        lokasi: data['lokasi'] ?? '',
        hargaPerJam: (data['hargaPerJam'] ?? 0) as int,
        jenis: data['jenis'] ?? '',
        statusVerifikasi: data['statusVerifikasi'] ?? 'menunggu',
      );
    }).toList();
  }

  Future<List<BookingEntity>> getAllBookings() async {
    final snap = await _firestore
        .collection('bookings')
        .orderBy('tanggal', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return BookingEntity(
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
    batch.update(
      _firestore.collection('fields').doc(fieldId),
      {'statusVerifikasi': status},
    );
    batch.update(
      _firestore.collection('users').doc(ownerUid),
      {'statusVerifikasi': status},
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