import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/core/services/firestore_service.dart';

class BookingService {
  final FirebaseFirestore _db = FirestoreService.instance;

  /// Ambil daftar jam yang sudah dibooking untuk lapangan tertentu pada tanggal tertentu
  Future<List<String>> getBookedSlots({
    required String fieldId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Query sederhana tanpa composite index
    final snap = await _db
        .collection('bookings')
        .where('fieldId', isEqualTo: fieldId)
        .get();

    final bookedSlots = <String>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      
      // Filter tanggal dan status secara client-side
      final tanggal = (data['tanggal'] as Timestamp?)?.toDate();
      if (tanggal == null) continue;
      if (tanggal.isBefore(startOfDay) || tanggal.isAfter(endOfDay)) continue;
      
      final status = data['status'] ?? '';
      if (status == 'dibatalkan') continue; // Abaikan yang dibatalkan
      
      final jamMulai = data['jamMulai'] ?? '';
      final jamSelesai = data['jamSelesai'] ?? '';
      if (jamMulai.isNotEmpty && jamSelesai.isNotEmpty) {
        bookedSlots.add('$jamMulai - $jamSelesai');
      }
    }
    return bookedSlots;
  }

  /// Buat booking baru
  Future<void> createBooking({
    required String fieldId,
    required String fieldName,
    required String userId,
    required String userName,
    required DateTime date,
    required List<String> timeSlots,
    required int pricePerHour,
  }) async {
    final batch = _db.batch();

    for (final slot in timeSlots) {
      final parts = slot.split(' - ');
      final docRef = _db.collection('bookings').doc();
      batch.set(docRef, {
        'fieldId': fieldId,
        'namaLapangan': fieldName,
        'userId': userId,
        'namaPenyewa': userName,
        'tanggal': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'jamMulai': parts[0].trim(),
        'jamSelesai': parts[1].trim(),
        'totalHarga': pricePerHour,
        'status': 'menunggu',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Ambil semua booking milik user tertentu
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    final bookings = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // Sort by createdAt descending (client-side)
    bookings.sort((a, b) {
      final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return bookings;
  }

  /// Batalkan booking
  Future<void> cancelBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'dibatalkan',
    });
  }
}
