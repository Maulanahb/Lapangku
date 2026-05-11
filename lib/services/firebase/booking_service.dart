import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/standards/constants/app_constants.dart';

/// Service layer untuk seluruh operasi booking di Firestore.
///
/// Menangani operasi lintas role:
/// - **Customer**: createBooking, uploadPaymentProof, cancelBooking
/// - **Mitra**: confirmBooking, rejectBooking, streamMitraBookingsByMitraId
/// - **Admin**: streamAllBookings
/// - **System**: auto-expire batas waktu bayar
class BookingService {
  final FirebaseFirestore _db = FirestoreService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate Booking ID format LPK-YYYYMMDD-XXX
  String _generateBookingId() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomDigits =
        (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return 'LPK-$dateStr-$randomDigits';
  }

  /// Helper privat: update status booking + tambah entry ke statusTimeline.
  ///
  /// Menghindari duplikasi kode di confirmBooking, rejectBooking, completeBooking, dll.
  /// [extraFields] digunakan untuk menambahkan data tambahan seperti alasanPenolakan.
  Future<void> _updateStatus(
    String bookingDocId, {
    required String newStatus,
    Map<String, dynamic>? extraFields,
  }) async {
    final doc = await _db.collection('bookings').doc(bookingDocId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');

    final currentStatus = doc.data()?['status'] ?? '';

    // Validasi transisi status
    if (!BookingStatusHelper.isValidTransition(currentStatus, newStatus)) {
      throw Exception(
          'Transisi status tidak valid: $currentStatus → $newStatus');
    }

    final now = DateTime.now();
    final timeline = List<Map<String, dynamic>>.from(
        doc.data()?['statusTimeline'] ?? []);
    timeline.add({
      'status': newStatus,
      'waktu': Timestamp.fromDate(now),
    });

    final updateData = <String, dynamic>{
      'status': newStatus,
      'statusTimeline': timeline,
      'updatedAt': Timestamp.fromDate(now),
      ...?extraFields,
    };

    await _db.collection('bookings').doc(bookingDocId).update(updateData);
  }

  /// Auto-expire booking yang melewati batas waktu pembayaran.
  /// Fire-and-forget — silent fail, akan di-retry pada request berikutnya.
  Future<void> _expireBooking(String docId, dynamic existingTimeline) async {
    try {
      final now = DateTime.now();
      final timeline = existingTimeline != null
          ? List<Map<String, dynamic>>.from(existingTimeline)
          : <Map<String, dynamic>>[];
      timeline.add({
        'status': BookingStatusHelper.expired,
        'waktu': Timestamp.fromDate(now),
      });

      await _db.collection('bookings').doc(docId).update({
        'status': BookingStatusHelper.expired,
        'statusTimeline': timeline,
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (_) {
      // Silent fail — akan di-expire pada request berikutnya
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMER ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// [Customer] Membuat booking baru.
  ///
  /// WAJIB menerima `mitraId` melalui [field.mitraId] agar query Mitra efisien.
  /// Status awal: `menunggu_bayar`
  Future<BookingModel> createBooking({
    required FieldModel field,
    required UserModel user,
    required DateTime date,
    required List<String> timeSlots,
    required String metodePembayaran,
    required int biayaLayanan,
    required String mitraId,
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
      mitraId: mitraId, // ← WAJIB: disimpan agar Mitra bisa query langsung
      fieldName: field.namaVenue.isNotEmpty
          ? '${field.namaVenue} - ${field.nama}'
          : field.nama,
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
      status: BookingStatusHelper.menungguBayar,
      statusTimeline: [
        {
          'status': BookingStatusHelper.menungguBayar,
          'waktu': Timestamp.fromDate(now),
        }
      ],
      batasWaktuBayar:
          now.add(const Duration(hours: AppConstants.paymentDeadlineHours)),
      createdAt: now,
      updatedAt: now,
    );
    print('=========================================');
    print('📋 CREATE BOOKING');
    print('   fieldId: ${field.id}');
    print('   mitraId param: $mitraId');
    print('   field.mitraId: ${field.mitraId}');
    print('   field.idPemilik: ${field.idPemilik}');
    print('=========================================');

    await docRef.set(booking.toFirestore());
    print('✅ Booking saved: ${booking.bookingId} | mitraId in doc: ${booking.mitraId}');
    return booking;
  }

  /// [Customer] Get slot yang sudah dipesan untuk tanggal tertentu.
  /// Juga auto-expire booking yang melewati batas waktu pembayaran.
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
    final now = DateTime.now();

    for (final doc in snap.docs) {
      final data = doc.data();

      final tanggal = (data['tanggal'] as Timestamp?)?.toDate();
      if (tanggal == null) continue;
      if (tanggal.isBefore(startOfDay) || tanggal.isAfter(endOfDay)) continue;

      final status = data['status'] ?? '';
      // Skip terminal states (tidak memblokir slot)
      if (status == BookingStatusHelper.dibatalkan ||
          status == BookingStatusHelper.expired ||
          status == BookingStatusHelper.ditolak) {
        continue;
      }

      // Auto-expire: jika menunggu_bayar tapi sudah lewat batas waktu
      if (status == BookingStatusHelper.menungguBayar) {
        final batasWaktu =
            (data['batasWaktuBayar'] as Timestamp?)?.toDate();
        if (batasWaktu != null && now.isAfter(batasWaktu)) {
          _expireBooking(doc.id, data['statusTimeline']);
          continue; // Skip slot ini, sudah expired
        }
      }

      final timeSlots = data['timeSlots'];
      if (timeSlots != null) {
        bookedSlots.addAll(List<String>.from(timeSlots));
      } else {
        // Fallback ke format lama
        final jamMulai = data['jamMulai'] ?? '';
        final jamSelesai = data['jamSelesai'] ?? '';
        if (jamMulai.isNotEmpty && jamSelesai.isNotEmpty) {
          bookedSlots.add('$jamMulai - $jamSelesai');
        }
      }
    }
    return bookedSlots;
  }

  /// [Customer] Get single booking by document ID.
  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// [Customer] Stream single booking untuk real-time updates.
  Stream<BookingModel?> streamBooking(String bookingId) {
    return _db
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return BookingModel.fromFirestore(doc);
    });
  }

  /// [Customer] Get semua booking milik user tertentu.
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    final bookings =
        snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    // Sort by createdAt descending
    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  /// [Customer] Upload bukti pembayaran transfer bank.
  /// Transisi: menunggu_bayar → menunggu_konfirmasi
  Future<void> uploadPaymentProof(String bookingId, File imageFile) async {
    final bookingDoc =
        await _db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw Exception('Booking tidak ditemukan');

    final booking = BookingModel.fromFirestore(bookingDoc);

    // Cek batas waktu pembayaran
    if (DateTime.now().isAfter(booking.batasWaktuBayar)) {
      await _expireBooking(bookingId, bookingDoc.data()?['statusTimeline']);
      throw Exception(
          'Batas waktu pembayaran telah terlewat. Booking otomatis expired.');
    }

    // Upload ke Firebase Storage
    final storageRef = _storage.ref().child(
        'payment_proofs/${booking.bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = await storageRef.putFile(imageFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    // Transisi status + simpan URL bukti
    await _updateStatus(
      bookingId,
      newStatus: BookingStatusHelper.menungguKonfirmasi,
      extraFields: {'buktiTransferUrl': imageUrl},
    );
  }

  /// [Customer] Upload DUMMY payment proof (for testing only).
  /// Transisi: menunggu_bayar → menunggu_konfirmasi
  Future<void> uploadDummyPaymentProof(String bookingId) async {
    const dummyUrl =
        'https://firebasestorage.googleapis.com/v0/b/lapangku-4e610.firebasestorage.app/o/placeholder%2Fdummy_payment.png?alt=media';

    await _updateStatus(
      bookingId,
      newStatus: BookingStatusHelper.menungguKonfirmasi,
      extraFields: {'buktiTransferUrl': dummyUrl},
    );
  }

  /// [Customer] Konfirmasi pembayaran QRIS (tanpa bukti transfer).
  /// Transisi: menunggu_bayar → menunggu_konfirmasi
  Future<void> confirmQrisPayment(String bookingId) async {
    await _updateStatus(
      bookingId,
      newStatus: BookingStatusHelper.menungguKonfirmasi,
    );
  }

  /// [Customer] Membatalkan booking.
  /// Valid dari: menunggu_bayar, menunggu_konfirmasi
  Future<void> cancelBooking(String bookingId) async {
    await _updateStatus(
      bookingId,
      newStatus: BookingStatusHelper.dibatalkan,
    );
  }

  /// Delete booking (hard delete)
  Future<void> deleteBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MITRA ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// [Mitra] Stream semua booking yang terkait Mitra berdasarkan mitraId.
  ///
  /// Lebih efisien daripada query whereIn fieldIds karena langsung
  /// menggunakan single field `mitraId` di Firestore.
  Stream<List<BookingModel>> streamMitraBookingsByMitraId(
    String mitraId, {
    String? statusFilter,
  }) {
    print('=========================================');
    print('🔍 STREAM MITRA BOOKINGS');
    print('   mitraId: "$mitraId"');
    print('   statusFilter: $statusFilter');
    print('=========================================');

    Query query = _db
        .collection('bookings')
        .where('mitraId', isEqualTo: mitraId);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snap) {
      final bookings =
          snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  /// [Mitra] Stream booking berdasarkan list fieldId (fallback/backward-compat).
  Stream<List<BookingModel>> streamMitraBookings(
    List<String> fieldIds, {
    String? statusFilter,
  }) {
    if (fieldIds.isEmpty) return Stream.value([]);

    final ids = fieldIds.take(AppConstants.firestoreWhereInLimit).toList();
    Query query = _db
        .collection('bookings')
        .where('fieldId', whereIn: ids);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snap) {
      final bookings =
          snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  /// [Mitra] Konfirmasi/setujui booking.
  /// Transisi: menunggu_konfirmasi → dikonfirmasi
  Future<void> confirmBooking(String bookingId) async {
    await _updateStatus(
      bookingId,
      newStatus: BookingStatusHelper.dikonfirmasi,
    );
  }

  /// [Mitra] Tolak booking dengan alasan opsional.
  /// Transisi: menunggu_konfirmasi → ditolak
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    await _updateStatus(
      bookingId,
      newStatus: BookingStatusHelper.ditolak,
      extraFields: {
        if (reason != null && reason.isNotEmpty) 'alasanPenolakan': reason,
      },
    );
  }

  /// [Mitra/System] Tandai booking sebagai selesai.
  /// Transisi: dikonfirmasi → selesai
  Future<void> completeBooking(String bookingId) async {
    await _updateStatus(
      bookingId,
      newStatus: BookingStatusHelper.selesai,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// [Admin] Stream seluruh booking secara real-time (diurutkan createdAt descending).
  /// Digunakan untuk dashboard Admin yang memonitor semua transaksi.
  Stream<List<BookingModel>> streamAllBookings({String? statusFilter}) {
    Query query = _db.collection('bookings');

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snap) {
      final bookings =
          snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }
}
