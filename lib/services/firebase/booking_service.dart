import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/models/auth/user_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirestoreService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Generate Booking ID format LPK-YYYYMMDD-XXX
  String _generateBookingId() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    // Generate 3 random digits (for simplicity, using timestamp suffix)
    final randomDigits = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return 'LPK-$dateStr-$randomDigits';
  }

  /// Get booked slots for a specific field and date
  Future<List<String>> getBookedSlots({
    required String fieldId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _db
        .collection('bookings')
        .where('fieldId', isEqualTo: fieldId)
        .get();

    final bookedSlots = <String>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      
      final tanggal = (data['tanggal'] as Timestamp?)?.toDate();
      if (tanggal == null) continue;
      if (tanggal.isBefore(startOfDay) || tanggal.isAfter(endOfDay)) continue;
      
      final status = data['status'] ?? '';
      // Exclude dibatalkan and expired
      if (status == 'dibatalkan' || status == 'expired') continue;
      
      final timeSlots = data['timeSlots'];
      if (timeSlots != null) {
        bookedSlots.addAll(List<String>.from(timeSlots));
      } else {
        // Fallback to old format
        final jamMulai = data['jamMulai'] ?? '';
        final jamSelesai = data['jamSelesai'] ?? '';
        if (jamMulai.isNotEmpty && jamSelesai.isNotEmpty) {
          bookedSlots.add('$jamMulai - $jamSelesai');
        }
      }
    }
    return bookedSlots;
  }

  /// Create a new booking
  Future<BookingModel> createBooking({
    required FieldModel field,
    required UserModel user,
    required DateTime date,
    required List<String> timeSlots,
    required String metodePembayaran,
    required int biayaLayanan,
  }) async {
    final docRef = _db.collection('bookings').doc();
    final now = DateTime.now();
    
    final int durasi = timeSlots.length;
    final int hargaLapangan = field.hargaPerJam * durasi;
    final int totalBayar = hargaLapangan + biayaLayanan;

    final booking = BookingModel(
      id: docRef.id,
      bookingId: _generateBookingId(),
      fieldId: field.id,
      fieldName: field.nama,
      fieldAddress: field.alamat,
      fieldCategory: field.kategori,
      fieldImageUrl: field.fotoUtama,
      userId: user.uid,
      userName: user.nama,
      tanggal: DateTime(date.year, date.month, date.day),
      timeSlots: timeSlots,
      durasi: durasi,
      hargaLapangan: hargaLapangan,
      biayaLayanan: biayaLayanan,
      totalBayar: totalBayar,
      metodePembayaran: metodePembayaran,
      status: 'menunggu_bayar',
      statusTimeline: [
        {'status': 'menunggu_bayar', 'waktu': Timestamp.fromDate(now)}
      ],
      batasWaktuBayar: now.add(const Duration(hours: 4)),
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(booking.toFirestore());
    return booking;
  }

  /// Get single booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Stream single booking for real-time updates
  Stream<BookingModel?> streamBooking(String bookingId) {
    return _db.collection('bookings').doc(bookingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BookingModel.fromFirestore(doc);
    });
  }

  /// Get all user bookings
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    final bookings = snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();

    // Sort by createdAt descending
    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return bookings;
  }

  /// Upload payment proof to Firebase Storage and update booking
  Future<void> uploadPaymentProof(String bookingId, File imageFile) async {
    final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw Exception('Booking tidak ditemukan');
    
    final booking = BookingModel.fromFirestore(bookingDoc);
    if (booking.status != 'menunggu_bayar') {
      throw Exception('Booking tidak dalam status menunggu bayar');
    }

    // Upload to Storage
    final storageRef = _storage.ref().child('payment_proofs/${booking.bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = await storageRef.putFile(imageFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    // Update Firestore
    final now = DateTime.now();
    final timeline = List<Map<String, dynamic>>.from(booking.statusTimeline);
    timeline.add({'status': 'menunggu_konfirmasi', 'waktu': Timestamp.fromDate(now)});

    await _db.collection('bookings').doc(bookingId).update({
      'buktiTransferUrl': imageUrl,
      'status': 'menunggu_konfirmasi',
      'statusTimeline': timeline,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');
    
    final status = doc.data()?['status'] ?? '';
    if (status != 'menunggu_bayar' && status != 'menunggu_konfirmasi') {
      throw Exception('Hanya pesanan yang belum dikonfirmasi yang dapat dibatalkan');
    }

    final now = DateTime.now();
    final timeline = List<Map<String, dynamic>>.from(doc.data()?['statusTimeline'] ?? []);
    timeline.add({'status': 'dibatalkan', 'waktu': Timestamp.fromDate(now)});

    await _db.collection('bookings').doc(bookingId).update({
      'status': 'dibatalkan',
      'statusTimeline': timeline,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Mitra ACTIONS
  // ─────────────────────────────────────────────────────────────────

  /// Stream semua booking milik Mitra berdasarkan list fieldId
  Stream<List<BookingModel>> streamMitraBookings(
    List<String> fieldIds, {
    String? statusFilter,
  }) {
    if (fieldIds.isEmpty) {
      return Stream.value([]);
    }
    // Firestore whereIn maksimal 30 item
    final ids = fieldIds.take(30).toList();
    Query query = _db
        .collection('bookings')
        .where('fieldId', whereIn: ids)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = _db
          .collection('bookings')
          .where('fieldId', whereIn: ids)
          .where('status', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => BookingModel.fromFirestore(d)).toList());
  }

  /// Konfirmasi booking oleh Mitra
  Future<void> confirmBooking(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');

    final now = DateTime.now();
    final timeline = List<Map<String, dynamic>>.from(
        doc.data()?['statusTimeline'] ?? []);
    timeline.add({
      'status': 'dikonfirmasi',
      'waktu': Timestamp.fromDate(now),
    });

    await _db.collection('bookings').doc(bookingId).update({
      'status': 'dikonfirmasi',
      'statusTimeline': timeline,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// Tolak booking oleh Mitra (dengan alasan opsional)
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');

    final now = DateTime.now();
    final timeline = List<Map<String, dynamic>>.from(
        doc.data()?['statusTimeline'] ?? []);
    timeline.add({
      'status': 'ditolak',
      'waktu': Timestamp.fromDate(now),
      if (reason != null && reason.isNotEmpty) 'alasan': reason,
    });

    await _db.collection('bookings').doc(bookingId).update({
      'status': 'ditolak',
      'alasanPenolakan': reason ?? '',
      'statusTimeline': timeline,
      'updatedAt': Timestamp.fromDate(now),
    });
  }
}
