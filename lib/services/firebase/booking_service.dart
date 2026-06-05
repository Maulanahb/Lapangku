import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/standards/constants/app_constants.dart';

/// Service layer untuk seluruh operasi booking di Firestore.
///
/// Menangani operasi lintas role:
/// - **Customer**: createBooking, cancelBooking
/// - **Mitra**: confirmBooking, rejectBooking, streamMitraBookingsByMitraId
/// - **Admin**: streamAllBookings
/// - **System**: auto-expire batas waktu bayar
class BookingService {
  final FirebaseFirestore _db = FirestoreService.instance;

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
  ///
  /// **PENTING — Asumsi Harga:**
  /// Perhitungan `hargaLapangan = field.hargaPerJam * timeSlots.length`
  /// mengasumsikan 1 slot = tepat 1 jam (misal: "08:00 - 09:00").
  /// Jika Mitra membuat slot berdurasi bukan 1 jam (misal: "08:00 - 09:30"),
  /// harga yang dihitung akan salah. Pastikan validasi pembuatan slot di sisi
  /// Mitra mengunci durasi per slot ke tepat 1 jam.
  Future<BookingModel> createBooking({
    required FieldModel field,
    required UserModel user,
    required DateTime date,
    required List<String> timeSlots,
    required String metodePembayaran,
    required int biayaLayanan,
    required String mitraId,
  }) async {
    // Validasi: minimal 1 slot harus dipilih
    if (timeSlots.isEmpty) {
      throw Exception('Minimal pilih 1 slot waktu untuk booking.');
    }

    // ══════════════════════════════════════════════════════════════════
    // ANTI DOUBLE-BOOKING: Cek slot yang sudah terpesan sebelum membuat
    // booking baru. Mencegah race condition dimana 2 customer memesan
    // slot yang sama dalam waktu bersamaan.
    // ══════════════════════════════════════════════════════════════════
    final existingSlots = await getBookedSlots(fieldId: field.id, date: date);
    final conflict = timeSlots.where((s) => existingSlots.contains(s)).toList();
    if (conflict.isNotEmpty) {
      throw Exception(
          'Slot ${conflict.join(", ")} sudah dipesan oleh orang lain. '
          'Silakan pilih slot lain.');
    }

    final docRef = _db.collection('bookings').doc();
    final now = DateTime.now();

    // Asumsi: 1 slot = 1 jam. Lihat doc comment di atas.
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
    debugPrint('=========================================');
    debugPrint('📋 CREATE BOOKING');
    debugPrint('   fieldId: ${field.id}');
    debugPrint('   mitraId param: $mitraId');
    debugPrint('   field.mitraId: ${field.mitraId}');
    debugPrint('   field.idPemilik: ${field.idPemilik}');
    debugPrint('=========================================');

    // ══════════════════════════════════════════════════════════════════
    // BATCH WRITE: Atomik — booking + notifikasi ditulis bersamaan.
    // Jika salah satu gagal, keduanya dibatalkan (konsistensi data).
    // ══════════════════════════════════════════════════════════════════
    final batch = _db.batch();

    // 1. Tulis dokumen booking
    batch.set(docRef, booking.toFirestore());

    // 2. Tulis dokumen notifikasi untuk Mitra
    final notifRef = _db.collection('notifikasi').doc();
    final String fieldDisplayName = field.namaVenue.isNotEmpty
        ? '${field.namaVenue} - ${field.nama}'
        : field.nama;
    final String dateFormatted = DateFormat('dd MMM yyyy').format(date);
    final String slotsFormatted = timeSlots.join(', ');

    batch.set(notifRef, {
      'mitraId': mitraId,
      'isRead': false,
      'title': 'Pesanan Baru!',
      'message': '${user.nama} memesan $fieldDisplayName pada $dateFormatted ($slotsFormatted)',
      'type': 'booking',
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'bookingId': booking.bookingId,
        'bookingDocId': docRef.id,
        'fieldId': field.id,
        'fieldName': fieldDisplayName,
        'userId': user.uid,
        'userName': user.nama,
      },
    });

    await batch.commit();
    debugPrint('✅ Booking + Notifikasi saved: ${booking.bookingId} | mitraId: ${booking.mitraId}');

    // ═══════════════════════════════════════════════════════════════════
    // MIDTRANS SNAP: Create payment transaction via Cloud Function
    // ═══════════════════════════════════════════════════════════════════
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast2')
          .httpsCallable('createMidtransTransaction');
      final result = await callable.call({
        'bookingId': docRef.id,
        'totalBayar': totalBayar,
        'customerName': user.nama,
        'customerEmail': user.email,
      });
      final snapToken = result.data['snap_token'] as String?;
      final paymentUrl = result.data['payment_url'] as String?;
      await docRef.update({
        'snapToken': snapToken,
        'paymentUrl': paymentUrl,
      });
      return booking.copyWith(snapToken: snapToken, paymentUrl: paymentUrl);
    } catch (e) {
      debugPrint('⚠️ Midtrans callable failed: $e');
      // Rollback: hapus booking dan notifikasi jika gagal generate link bayar
      final rollbackBatch = _db.batch();
      rollbackBatch.delete(docRef);
      rollbackBatch.delete(notifRef);
      await rollbackBatch.commit();
      throw Exception('Sistem gagal menghubungi server pembayaran (Midtrans). Silakan coba lagi.');
    }
  }

  /// [Customer] Stream real-time slot yang sudah dipesan & ditutup untuk tanggal tertentu.
  /// Juga memblokir slot dari pengajuan reschedule yang masih pending.
  Stream<List<String>> streamBookedSlots({
    required String fieldId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    final controller = StreamController<List<String>>.broadcast();
    
    List<String> currentBooked = [];
    List<String> currentClosed = [];
    List<String> currentRescheduleSlots = [];
    
    void emit() {
      final combined = <String>{...currentBooked, ...currentClosed, ...currentRescheduleSlots}.toList();
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }
    
    // Sub1: Listen to existing bookings on this date
    final sub1 = _db
        .collection('bookings')
        .where('fieldId', isEqualTo: fieldId)
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen((snap) {
      final slots = <String>[];
      final now = DateTime.now();
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        if (status == BookingStatusHelper.dibatalkan ||
            status == BookingStatusHelper.expired ||
            status == BookingStatusHelper.ditolak) {
          continue;
        }
        if (status == BookingStatusHelper.menungguBayar) {
          final batasWaktu = (data['batasWaktuBayar'] as Timestamp?)?.toDate();
          if (batasWaktu != null && now.isAfter(batasWaktu)) {
            continue;
          }
        }
        final timeSlots = data['timeSlots'];
        if (timeSlots != null) {
          slots.addAll(List<String>.from(timeSlots));
        } else {
          final jamMulai = data['jamMulai'] ?? '';
          final jamSelesai = data['jamSelesai'] ?? '';
          if (jamMulai.isNotEmpty && jamSelesai.isNotEmpty) {
            slots.add('$jamMulai - $jamSelesai');
          }
        }
      }
      currentBooked = slots;
      emit();
    }, onError: (e) {
      if (!controller.isClosed) controller.addError(e);
    });

    // Sub2: Listen to manually closed slots by Mitra
    final sub2 = _db
        .collection('schedules')
        .where('fieldId', isEqualTo: fieldId)
        .where('tanggal', isEqualTo: dateStr)
        .where('status', isEqualTo: 'ditutup')
        .snapshots()
        .listen((snap) {
      final slots = <String>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final jam = data['jam'] as String?;
        if (jam != null && jam.isNotEmpty) {
          try {
            final parts = jam.split(':');
            final hour = int.parse(parts[0]);
            final startSlot = '${hour.toString().padLeft(2, '0')}:00';
            final endSlot = '${(hour + 1).toString().padLeft(2, '0')}:00';
            slots.add('$startSlot - $endSlot');
          } catch (_) {}
        }
      }
      currentClosed = slots;
      emit();
    }, onError: (e) {
      if (!controller.isClosed) controller.addError(e);
    });

    // Sub3: Listen to pending reschedule requests targeting this date.
    // When a customer requests a reschedule to this date, the new time slots
    // should be blocked even though the reschedule hasn't been approved yet.
    final sub3 = _db
        .collection('bookings')
        .where('fieldId', isEqualTo: fieldId)
        .where('rescheduleStatus', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      final slots = <String>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final rescheduleDate = (data['rescheduleDate'] as Timestamp?)?.toDate();
        if (rescheduleDate == null) continue;
        
        // Check if the reschedule targets this date
        final reschedDay = DateTime(rescheduleDate.year, rescheduleDate.month, rescheduleDate.day);
        if (reschedDay.isAtSameMomentAs(startOfDay)) {
          final rescheduleTimeSlots = data['rescheduleTimeSlots'];
          if (rescheduleTimeSlots != null) {
            slots.addAll(List<String>.from(rescheduleTimeSlots));
          }
        }
      }
      currentRescheduleSlots = slots;
      emit();
    }, onError: (e) {
      if (!controller.isClosed) controller.addError(e);
    });
    
    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
    };
    
    return controller.stream;
  }

  /// [Customer] Get slot yang sudah dipesan untuk tanggal tertentu.
  /// Juga auto-expire booking yang melewati batas waktu pembayaran.
  Future<List<String>> getBookedSlots({
    required String fieldId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Filter tanggal di Firestore (server-side) agar hanya booking pada
    // tanggal yang diminta yang diambil. Menghindari kebocoran reads yang
    // sangat mahal — sebelumnya SEMUA riwayat booking lapangan di-download.
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

    // Ambil slot yang ditutup secara manual oleh Mitra dari koleksi 'schedules'
    // PENTING: Mitra menyimpan jadwal via jadwal_lapangan.dart ke koleksi
    // 'schedules' dengan field 'fieldId' (bukan 'jadwal'/'lapangan_id').
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final jadwalSnap = await _db
          .collection('schedules')
          .where('fieldId', isEqualTo: fieldId)
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

    // Juga blokir slot dari pengajuan reschedule yang masih pending
    try {
      final reschedSnap = await _db
          .collection('bookings')
          .where('fieldId', isEqualTo: fieldId)
          .where('rescheduleStatus', isEqualTo: 'pending')
          .get();

      for (final doc in reschedSnap.docs) {
        final data = doc.data();
        final rescheduleDate = (data['rescheduleDate'] as Timestamp?)?.toDate();
        if (rescheduleDate == null) continue;

        final reschedDay = DateTime(rescheduleDate.year, rescheduleDate.month, rescheduleDate.day);
        if (reschedDay.isAtSameMomentAs(startOfDay)) {
          final rescheduleTimeSlots = data['rescheduleTimeSlots'];
          if (rescheduleTimeSlots != null) {
            bookedSlots.addAll(List<String>.from(rescheduleTimeSlots));
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching pending reschedule slots: $e');
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

  /// [Customer] Get booking milik user tertentu.
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

    return snap.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .where((booking) => !booking.isHiddenByCustomer)
        .toList();
  }

  /// [Customer] Stream booking milik user tertentu secara real-time.
  Stream<List<BookingModel>> streamUserBookings(String userId, {int limit = 50}) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .where((booking) => !booking.isHiddenByCustomer)
            .toList());
  }

  /// [Customer] Membatalkan booking.
  /// Valid dari: menunggu_bayar
  Future<void> cancelBooking(String bookingId) async {
    await _updateStatus(
      bookingId,
      newStatus: BookingStatusHelper.dibatalkan,
    );
  }

  /// Delete booking (hard delete) - Hanya untuk Admin
  Future<void> deleteBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).delete();
  }

  /// [Customer] Hapus booking dari riwayat (Soft Delete)
  Future<void> hideBookingForCustomer(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'isHiddenByCustomer': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// [Mitra] Hapus booking dari riwayat (Soft Delete)
  Future<void> hideBookingForMitra(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'isHiddenByMitra': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// [Customer] Mengajukan perubahan jadwal (Reschedule)
  Future<void> requestReschedule(String bookingId, DateTime newDate, List<String> newTimeSlots, String reason) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');
    
    final booking = BookingModel.fromFirestore(doc);
    
    // Validasi 2 jam sebelum main
    if (booking.timeSlots.isNotEmpty) {
      final startTimeStr = booking.timeSlots.first.split(' - ')[0];
      final parts = startTimeStr.split(':');
      if (parts.length >= 2) {
        final startHour = int.tryParse(parts[0]) ?? 0;
        final startMinute = int.tryParse(parts[1]) ?? 0;
        final startDateTime = DateTime(
          booking.tanggal.year,
          booking.tanggal.month,
          booking.tanggal.day,
          startHour,
          startMinute,
        );
        
        final diff = startDateTime.difference(DateTime.now());
        if (diff.inHours < 2) {
          throw Exception('Batas waktu pengajuan reschedule (Maksimal 2 jam sebelum jadwal bermain) telah terlewati.');
        }
      }
    }
    
    final batch = _db.batch();

    batch.update(_db.collection('bookings').doc(bookingId), {
      'isRescheduleRequested': true,
      'rescheduleDate': Timestamp.fromDate(newDate),
      'rescheduleTimeSlots': newTimeSlots,
      'rescheduleReason': reason,
      'rescheduleStatus': 'pending',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    final String dateFormatted = DateFormat('dd MMM yyyy').format(newDate);
    final String slotsFormatted = newTimeSlots.join(', ');

    final notifRef = _db.collection('notifikasi').doc();
    batch.set(notifRef, {
      'mitraId': booking.mitraId,
      'isRead': false,
      'title': 'Pengajuan Reschedule',
      'message': '${booking.userName} mengajukan perubahan jadwal ke $dateFormatted ($slotsFormatted)',
      'type': 'reschedule',
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'bookingId': booking.bookingId,
        'bookingDocId': bookingId,
        'fieldId': booking.fieldId,
        'fieldName': booking.fieldName,
        'userId': booking.userId,
        'userName': booking.userName,
      },
    });

    await batch.commit();
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
    debugPrint('=========================================');
    debugPrint('🔍 STREAM MITRA BOOKINGS');
    debugPrint('   mitraId: "$mitraId"');
    debugPrint('   statusFilter: $statusFilter');
    debugPrint('=========================================');

    Query query = _db
        .collection('bookings')
        .where('mitraId', isEqualTo: mitraId);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    query = query.limit(150);

    return query.snapshots().map((snap) {
      final bookings =
          snap.docs.map((d) => BookingModel.fromFirestore(d))
          .where((booking) => !booking.isHiddenByMitra)
          .toList();
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

    query = query.limit(150);

    return query.snapshots().map((snap) {
      final bookings =
          snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  /// [Mitra] Konfirmasi/setujui booking.
  /// Transisi: dikonfirmasi → selesai (or manual override)
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

  /// [Mitra] Validasi E-Ticket dari QR Code dan selesaikan booking.
  ///
  /// Validasi meliputi:
  /// 1. Apakah tiket ada di database
  /// 2. Apakah tiket milik lapangan mitra yang scan
  /// 3. Apakah tiket sudah pernah digunakan
  /// 4. Apakah status tiket valid (dikonfirmasi)
  Future<BookingModel> validateAndCompleteBooking(
    String bookingId,
    String mitraId,
  ) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Tiket tidak ditemukan atau tidak valid.');
    }

    final booking = BookingModel.fromFirestore(doc);

    // Cek kepemilikan — tiket harus milik lapangan mitra yang scan
    if (booking.mitraId != mitraId) {
      throw Exception('Akses Ditolak: Tiket ini bukan untuk lapangan Anda.');
    }

    // Cek apakah sudah pernah di-scan
    if (booking.status == BookingStatusHelper.selesai) {
      throw Exception('Tiket ini sudah pernah digunakan (Selesai).');
    }

    // Cek status — hanya tiket dikonfirmasi yang bisa di-scan
    if (booking.status != BookingStatusHelper.dikonfirmasi) {
      throw Exception(
        'Tiket belum siap. Status saat ini: ${BookingStatusHelper.getLabel(booking.status)}',
      );
    }

    // Cek apakah e-ticket sudah hangus (melewati batas waktu main)
    if (booking.isTicketExpired) {
      throw Exception('Tiket ini sudah hangus (melewati waktu selesai bermain).');
    }

    // Semua validasi lulus — ubah status jadi selesai
    await _updateStatus(bookingId, newStatus: BookingStatusHelper.selesai);

    // Return booking yang sudah diupdate untuk ditampilkan di UI
    return booking.copyWith(status: BookingStatusHelper.selesai);
  }

  /// [Mitra] Menyetujui pengajuan reschedule
  Future<void> approveReschedule(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');
    
    final booking = BookingModel.fromFirestore(doc);
    if (!booking.isRescheduleRequested || booking.rescheduleStatus != 'pending') {
      throw Exception('Tidak ada pengajuan reschedule yang valid.');
    }
    
    final batch = _db.batch();
    
    batch.update(_db.collection('bookings').doc(bookingId), {
      'tanggal': Timestamp.fromDate(booking.rescheduleDate!),
      'timeSlots': booking.rescheduleTimeSlots,
      'durasi': booking.rescheduleTimeSlots!.length,
      'isRescheduleRequested': false,
      'rescheduleStatus': 'approved',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    
    // Kirim Notifikasi ke Customer
    final notifRef = _db.collection('notifikasi').doc();
    batch.set(notifRef, {
      'customer_id': booking.userId,
      'isRead': false,
      'title': 'Reschedule Disetujui',
      'message': 'Pengajuan reschedule Anda untuk lapangan ${booking.fieldName} telah disetujui.',
      'type': 'reschedule',
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'bookingId': booking.bookingId,
        'bookingDocId': bookingId,
      },
    });
    
    await batch.commit();
  }

  /// [Mitra] Menolak pengajuan reschedule
  Future<void> rejectReschedule(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking tidak ditemukan');
    final booking = BookingModel.fromFirestore(doc);
    
    final batch = _db.batch();
    
    batch.update(_db.collection('bookings').doc(bookingId), {
      'isRescheduleRequested': false,
      'rescheduleStatus': 'rejected',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    
    // Kirim Notifikasi ke Customer
    final notifRef = _db.collection('notifikasi').doc();
    batch.set(notifRef, {
      'customer_id': booking.userId,
      'isRead': false,
      'title': 'Reschedule Ditolak',
      'message': 'Maaf, pengajuan reschedule Anda untuk lapangan ${booking.fieldName} tidak dapat disetujui.',
      'type': 'reschedule',
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'bookingId': booking.bookingId,
        'bookingDocId': bookingId,
      },
    });
    
    await batch.commit();
  }

  /// [Mitra] Buat booking offline/manual untuk memblokir slot.
  ///
  /// Digunakan ketika ada penyewa yang memesan langsung (via telepon/WA/datang).
  /// Status langsung `dikonfirmasi` agar slot otomatis terblokir.
  Future<BookingModel> createOfflineBooking({
    required String fieldId,
    required String mitraId,
    required String fieldName,
    required String fieldAddress,
    required String fieldCategory,
    required String fieldImageUrl,
    required DateTime date,
    required List<String> timeSlots,
    required int hargaPerJam,
    required String namaPenyewa,
    String catatan = '',
  }) async {
    final docRef = _db.collection('bookings').doc();
    final now = DateTime.now();
    final int durasi = timeSlots.length;
    final int totalBayar = hargaPerJam * durasi;

    final booking = BookingModel(
      id: docRef.id,
      bookingId: _generateBookingId(),
      fieldId: fieldId,
      mitraId: mitraId,
      fieldName: fieldName,
      fieldAddress: fieldAddress,
      fieldCategory: fieldCategory,
      fieldImageUrl: fieldImageUrl,
      userId: 'offline_$mitraId',
      userName: namaPenyewa,
      tanggal: DateTime(date.year, date.month, date.day),
      timeSlots: timeSlots,
      durasi: durasi,
      hargaLapangan: totalBayar,
      biayaLayanan: 0,
      totalBayar: totalBayar,
      metodePembayaran: 'offline',
      status: BookingStatusHelper.dikonfirmasi,
      statusTimeline: [
        {
          'status': BookingStatusHelper.dikonfirmasi,
          'waktu': Timestamp.fromDate(now),
        }
      ],
      batasWaktuBayar: now,
      createdAt: now,
      updatedAt: now,
    );

    final data = booking.toFirestore();
    if (catatan.isNotEmpty) data['catatan'] = catatan;
    data['isOfflineBooking'] = true;

    await docRef.set(data);
    return booking;
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
    
    // Gunakan limit agar tidak fetch ribuan dokumen ke HP admin
    query = query.limit(150);

    return query.snapshots().map((snap) {
      final bookings =
          snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }
}
