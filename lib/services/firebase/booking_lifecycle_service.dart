import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/standards/constants/app_constants.dart';
import 'package:lapangku/services/firebase_storage_service.dart';

/// Service layer utama untuk seluruh siklus hidup booking (Booking Lifecycle).
///
/// Menangani operasi lintas role:
/// - **Customer**: createBooking, uploadPaymentProof, cancelBooking
/// - **Mitra**: confirmBooking, rejectBooking, streamMitraBookings
/// - **Admin**: streamAllBookings, getBookingStats, forceUpdateStatus
/// - **System**: auto-expire, auto-complete
///
/// Semua transisi status divalidasi sebelum dieksekusi.
class BookingLifecycleService {
  final FirebaseFirestore _db = FirestoreService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED: Booking ID Generator
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED: Validasi & Helper
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validasi dan lakukan transisi status booking dengan timeline tracking.
  /// Melempar Exception jika transisi tidak valid.
  Future<void> _transitionStatus(
    String bookingDocId, {
    required String toStatus,
    Map<String, dynamic>? extraData,
  }) async {
    final doc = await _db.collection('bookings').doc(bookingDocId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');

    final currentStatus = doc.data()?['status'] ?? '';

    // Validasi transisi
    if (!BookingStatusHelper.isValidTransition(currentStatus, toStatus)) {
      throw Exception(
          'Transisi status tidak valid: $currentStatus → $toStatus');
    }

    final now = DateTime.now();
    final timeline = List<Map<String, dynamic>>.from(
        doc.data()?['statusTimeline'] ?? []);
    timeline.add({
      'status': toStatus,
      'waktu': Timestamp.fromDate(now),
    });

    final updateData = <String, dynamic>{
      'status': toStatus,
      'statusTimeline': timeline,
      'updatedAt': Timestamp.fromDate(now),
      ...?extraData,
    };

    await _db.collection('bookings').doc(bookingDocId).update(updateData);
    debugPrint('📋 Booking $bookingDocId: $currentStatus → $toStatus');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMER ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// [Customer] Membuat booking baru.
  ///
  /// Status awal: `menunggu_bayar`
  /// Data `mitraId` diambil dari FieldModel agar Mitra bisa query langsung.
  Future<BookingModel> createBooking({
    required FieldModel field,
    required UserModel user,
    required DateTime date,
    required List<String> timeSlots,
    required String metodePembayaran,
    required int biayaLayanan,
  }) async {
    // Validasi: pastikan slot belum diambil
    final existingSlots = await getBookedSlots(
      fieldId: field.id,
      date: date,
    );
    final conflict = timeSlots.where((s) => existingSlots.contains(s)).toList();
    if (conflict.isNotEmpty) {
      throw Exception(
          'Slot ${conflict.join(", ")} sudah dipesan. Silakan pilih slot lain.');
    }

    final docRef = _db.collection('bookings').doc();
    final now = DateTime.now();

    final int durasi = timeSlots.length;
    final int hargaLapangan = field.hargaPerJam * durasi;
    final int totalBayar = hargaLapangan + biayaLayanan;

    final booking = BookingModel(
      id: docRef.id,
      bookingId: _generateBookingId(),
      fieldId: field.id,
      mitraId: field.mitraId, // ← KEY: Simpan mitraId untuk query Mitra
      fieldName: field.namaVenue.isNotEmpty
          ? '${field.namaVenue} - ${field.nama}'
          : field.nama,
      fieldAddress: field.alamat,
      fieldCategory: field.kategori,
      fieldImageUrl: field.fotoUtama,
      userId: user.uid,
      userName: user.nama,
      userAvatarUrl: user.avatarUrl,
      tanggal: DateTime(date.year, date.month, date.day),
      timeSlots: timeSlots,
      durasi: durasi,
      hargaLapangan: hargaLapangan,
      biayaLayanan: biayaLayanan,
      totalBayar: totalBayar,
      metodePembayaran: metodePembayaran,
      status: BookingStatusHelper.menungguBayar,
      statusTimeline: [
        {'status': BookingStatusHelper.menungguBayar, 'waktu': Timestamp.fromDate(now)}
      ],
      batasWaktuBayar:
          now.add(const Duration(hours: AppConstants.paymentDeadlineHours)),
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(booking.toFirestore());
    debugPrint('✅ Booking ${booking.bookingId} created for field ${field.id}');
    return booking;
  }

  /// [Customer] Membatalkan booking.
  /// Valid dari: menunggu_bayar
  Future<void> cancelBooking(String bookingId) async {
    await _transitionStatus(
      bookingId,
      toStatus: BookingStatusHelper.dibatalkan,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MITRA ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// [Mitra] Konfirmasi/setujui booking.
  /// Transisi: dikonfirmasi → selesai (or manual override)
  Future<void> confirmBooking(String bookingId) async {
    await _transitionStatus(
      bookingId,
      toStatus: BookingStatusHelper.dikonfirmasi,
    );
  }

  /// [Mitra] Tolak booking dengan alasan opsional.
  /// Transisi: dikonfirmasi → ditolak
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    await _transitionStatus(
      bookingId,
      toStatus: BookingStatusHelper.ditolak,
      extraData: {
        if (reason != null && reason.isNotEmpty) 'alasanPenolakan': reason,
      },
    );
  }

  /// [Mitra] Stream semua booking yang terkait lapangan Mitra.
  /// Menggunakan `mitraId` langsung (lebih efisien daripada whereIn fieldIds).
  Stream<List<BookingModel>> streamMitraBookingsByMitraId(
    String mitraId, {
    String? statusFilter,
  }) {
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
  Stream<List<BookingModel>> streamMitraBookingsByFieldIds(
    List<String> fieldIds, {
    String? statusFilter,
  }) {
    if (fieldIds.isEmpty) return Stream.value([]);

    final ids =
        fieldIds.take(AppConstants.firestoreWhereInLimit).toList();
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// [Admin] Stream seluruh booking secara real-time.
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

  /// [Admin] Get statistik booking untuk dashboard.
  Future<Map<String, dynamic>> getBookingStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await Future.wait([
      // Total bookings hari ini
      _db
          .collection('bookings')
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
          .get(),
      // Booking menunggu bayar
      _db
          .collection('bookings')
          .where('status', isEqualTo: BookingStatusHelper.menungguBayar)
          .get(),
      // Booking selesai (semua waktu)
      _db
          .collection('bookings')
          .where('status', isEqualTo: BookingStatusHelper.selesai)
          .get(),
      // Booking dikonfirmasi
      _db
          .collection('bookings')
          .where('status', isEqualTo: BookingStatusHelper.dikonfirmasi)
          .get(),
    ]);

    final selesaiDocs = results[2] as QuerySnapshot;
    final dikonfirmasiDocs = results[3] as QuerySnapshot;
    
    // Hitung total pendapatan dari booking selesai + dikonfirmasi
    int totalPendapatan = 0;
    for (final doc in selesaiDocs.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      totalPendapatan += (data['totalBayar'] ?? data['totalHarga'] ?? 0) as int;
    }
    for (final doc in dikonfirmasiDocs.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      totalPendapatan += (data['totalBayar'] ?? data['totalHarga'] ?? 0) as int;
    }

    return {
      'pesananHariIni': results[0].size,
      'menungguBayar': results[1].size,
      'totalSelesai': selesaiDocs.size,
      'totalDikonfirmasi': dikonfirmasiDocs.size,
      'totalPendapatan': totalPendapatan,
    };
  }

  /// [Admin] Force-update status booking (untuk kasus darurat).
  /// Bypass validasi transisi normal.
  Future<void> forceUpdateBookingStatus(
    String bookingId, {
    required String newStatus,
    String? reason,
  }) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');

    final now = DateTime.now();
    final timeline = List<Map<String, dynamic>>.from(
        doc.data()?['statusTimeline'] ?? []);
    timeline.add({
      'status': newStatus,
      'waktu': Timestamp.fromDate(now),
      'by': 'admin',
      if (reason != null) 'catatan': reason,
    });

    await _db.collection('bookings').doc(bookingId).update({
      'status': newStatus,
      'statusTimeline': timeline,
      'updatedAt': Timestamp.fromDate(now),
    });

    debugPrint('⚠️ Admin force-update: $bookingId → $newStatus');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEM ACTIONS (Auto-expire, Auto-complete)
  // ═══════════════════════════════════════════════════════════════════════════

  /// [System] Auto-expire booking yang melewati batas waktu pembayaran.
  Future<void> _expireBooking(
      String docId, dynamic existingTimeline) async {
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
      debugPrint('⏰ Booking $docId expired (batas waktu terlewat)');
    } catch (_) {
      // Silent fail — akan di-expire pada request berikutnya
    }
  }

  /// [System] Tandai booking sebagai selesai.
  /// Transisi: dikonfirmasi → selesai (setelah waktu main terlewat)
  Future<void> completeBooking(String bookingId) async {
    await _transitionStatus(
      bookingId,
      toStatus: BookingStatusHelper.selesai,
    );
  }

  /// [System] Scan dan auto-complete booking yang waktu mainnya sudah lewat.
  /// Dipanggil secara periodik atau saat Mitra membuka dashboard.
  Future<int> autoCompleteExpiredBookings() async {
    final now = DateTime.now();
    int completedCount = 0;

    final snap = await _db
        .collection('bookings')
        .where('status', isEqualTo: BookingStatusHelper.dikonfirmasi)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final tanggal = (data['tanggal'] as Timestamp?)?.toDate();
      if (tanggal == null) continue;

      final timeSlots = List<String>.from(data['timeSlots'] ?? []);
      if (timeSlots.isEmpty) continue;

      // Ambil jam selesai dari slot terakhir (misal "20:00 - 21:00" → 21:00)
      try {
        final lastSlot = timeSlots.last;
        final endTimeStr = lastSlot.split(' - ').last.trim();
        final parts = endTimeStr.split(':');
        final endDateTime = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        if (now.isAfter(endDateTime)) {
          await completeBooking(doc.id);
          completedCount++;
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing time for booking ${doc.id}: $e');
      }
    }

    if (completedCount > 0) {
      debugPrint('✅ Auto-completed $completedCount bookings');
    }
    return completedCount;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED: Query Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get booked slots untuk tanggal tertentu (dipakai saat Customer memilih jam).
  /// Juga auto-expire booking yang melewati batas waktu.
  Future<List<String>> getBookedSlots({
    required String fieldId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Filter tanggal di Firestore (server-side) agar hanya booking pada
    // tanggal yang diminta yang diambil. Menghindari kebocoran reads yang mahal.
    final snap = await _db
        .collection('bookings')
        .where('fieldId', isEqualTo: fieldId)
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final bookedSlots = <String>[];
    final now = DateTime.now();

    for (final doc in snap.docs) {
      final data = doc.data();

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
          continue;
        }
      }

      final timeSlots = data['timeSlots'];
      if (timeSlots != null) {
        bookedSlots.addAll(List<String>.from(timeSlots));
      } else {
        final jamMulai = data['jamMulai'] ?? '';
        final jamSelesai = data['jamSelesai'] ?? '';
        if (jamMulai.isNotEmpty && jamSelesai.isNotEmpty) {
          bookedSlots.add('$jamMulai - $jamSelesai');
        }
      }
    }

    // Ambil slot yang ditutup secara manual oleh Mitra dari koleksi 'jadwal'
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final jadwalSnap = await _db
          .collection('jadwal')
          .where('lapangan_id', isEqualTo: fieldId)
          .where('tanggal', isEqualTo: dateStr)
          .where('status', isEqualTo: 'ditutup')
          .get();

      for (final doc in jadwalSnap.docs) {
        final data = doc.data();
        final jam = data['jam'] as String?;
        if (jam != null && jam.isNotEmpty) {
          final parts = jam.split(':');
          final hour = int.parse(parts[0]);
          final nextHour = hour + 1;
          final startSlot = '${hour.toString().padLeft(2, '0')}:00';
          final endSlot = '${nextHour.toString().padLeft(2, '0')}:00';
          bookedSlots.add('$startSlot - $endSlot');
        }
      }
    } catch (e) {
      // Fail-safe jika ada error parsing atau query
      debugPrint('Error fetching/parsing manual closed slots: $e');
    }

    return bookedSlots;
  }

  /// Get single booking by document ID.
  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Stream single booking untuk real-time updates.
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

  /// Get booking milik user (Customer).
  ///
  /// Menggunakan orderBy + limit agar tidak mendownload seluruh riwayat
  /// booking sejak akun dibuat. Default limit 50 booking terbaru.
  Future<List<BookingModel>> getUserBookings(String userId, {int limit = 50}) async {
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
  }

  /// Delete booking (hard delete, hanya untuk Admin atau sistem).
  Future<void> deleteBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).delete();
  }
}
