import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper untuk konstanta status dan validasi transisi booking.
///
/// Flow: menunggu_bayar → dikonfirmasi → selesai
///       menunggu_bayar → expired / dibatalkan
///       dikonfirmasi → selesai / dibatalkan / ditolak
class BookingStatusHelper {
  BookingStatusHelper._();

  // ─── String Constants (Firestore values) ─────────────────────────────────
  static const String menungguBayar = 'menunggu_bayar';
  static const String dikonfirmasi = 'dikonfirmasi';
  static const String selesai = 'selesai';
  static const String dibatalkan = 'dibatalkan';
  static const String ditolak = 'ditolak';
  static const String expired = 'expired';

  /// Status yang dianggap "aktif" (memblokir slot waktu)
  static const List<String> activeStatuses = [
    menungguBayar,
    dikonfirmasi,
  ];

  /// Status yang dianggap "selesai" (terminal state)
  static const List<String> terminalStatuses = [
    selesai,
    dibatalkan,
    ditolak,
    expired,
  ];

  /// Daftar semua status untuk validasi
  static const List<String> allStatuses = [
    menungguBayar,
    dikonfirmasi,
    selesai,
    dibatalkan,
    ditolak,
    expired,
  ];

  /// Cek apakah transisi status valid
  static bool isValidTransition(String from, String to) {
    final validTransitions = <String, List<String>>{
      menungguBayar: [dikonfirmasi, expired, dibatalkan],
      dikonfirmasi: [selesai, dibatalkan, ditolak],
    };
    return validTransitions[from]?.contains(to) ?? false;
  }

  /// Label user-friendly untuk ditampilkan di UI
  static String getLabel(String status) {
    switch (status) {
      case menungguBayar:
        return 'Menunggu Pembayaran';
      case dikonfirmasi:
        return 'Dikonfirmasi';
      case selesai:
        return 'Selesai';
      case dibatalkan:
        return 'Dibatalkan';
      case ditolak:
        return 'Ditolak';
      case expired:
        return 'Melewati Batas';
      default:
        return status;
    }
  }
}

class BookingModel {
  final String id;
  final String bookingId; // LPK-YYYYMMDD-XXX
  final String fieldId;
  final String mitraId; // ID pemilik lapangan untuk query langsung oleh Mitra
  final String fieldName;
  final String fieldAddress;
  final String fieldCategory;
  final String fieldImageUrl;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final DateTime tanggal;
  final List<String> timeSlots;
  final int durasi; // in hours
  final int hargaLapangan;
  final int biayaLayanan;
  final int totalBayar;
  final String metodePembayaran;
  final String status;
  final String? snapToken;
  final String? paymentUrl;
  final String? paymentTransactionId;
  final List<Map<String, dynamic>> statusTimeline; // [{status: '...', waktu: Timestamp}]
  final DateTime batasWaktuBayar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isReviewed;
  
  // Reschedule Fields
  final bool isRescheduleRequested;
  final DateTime? rescheduleDate;
  final List<String>? rescheduleTimeSlots;
  final String? rescheduleReason;
  final String? rescheduleStatus; // 'pending', 'approved', 'rejected'

  const BookingModel({
    required this.id,
    required this.bookingId,
    required this.fieldId,
    required this.mitraId,
    required this.fieldName,
    required this.fieldAddress,
    required this.fieldCategory,
    required this.fieldImageUrl,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.tanggal,
    required this.timeSlots,
    required this.durasi,
    required this.hargaLapangan,
    required this.biayaLayanan,
    required this.totalBayar,
    required this.metodePembayaran,
    required this.status,
    this.snapToken,
    this.paymentUrl,
    this.paymentTransactionId,
    required this.statusTimeline,
    required this.batasWaktuBayar,
    required this.createdAt,
    required this.updatedAt,
    this.isReviewed = false,
    this.isRescheduleRequested = false,
    this.rescheduleDate,
    this.rescheduleTimeSlots,
    this.rescheduleReason,
    this.rescheduleStatus,
  });

  // ─── Computed Properties ──────────────────────────────────────────────────

  /// Apakah booking masih aktif (memblokir slot)
  bool get isActive => BookingStatusHelper.activeStatuses.contains(status);

  /// Apakah booking sudah di terminal state
  bool get isTerminal => BookingStatusHelper.terminalStatuses.contains(status);

  /// Apakah pembayaran sudah melewati batas waktu
  bool get isPaymentExpired =>
      status == BookingStatusHelper.menungguBayar &&
      DateTime.now().isAfter(batasWaktuBayar);

  /// Apakah e-ticket sudah hangus (melewati jam selesai main)
  bool get isTicketExpired {
    if (status != BookingStatusHelper.dikonfirmasi) return false;
    if (timeSlots.isEmpty) return false;

    try {
      final lastSlot = timeSlots.last;
      final endTimeStr = lastSlot.split(' - ')[1];
      final parts = endTimeStr.split(':');
      if (parts.length >= 2) {
        final endHour = int.tryParse(parts[0]) ?? 0;
        final endMinute = int.tryParse(parts[1]) ?? 0;
        DateTime endDateTime = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          endHour,
          endMinute,
        );
        
        // Jika endHour adalah 0 (misal 00:00), maka itu berarti pergantian hari (besoknya)
        if (endHour == 0 && endMinute == 0) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }
        
        return DateTime.now().isAfter(endDateTime);
      }
    } catch (_) {}
    return false;
  }

  // ─── Factory: fromFirestore ───────────────────────────────────────────────

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    // Parse timeSlots — fallback ke format lama (jamMulai/jamSelesai)
    List<String> slots = [];
    if (data['timeSlots'] != null) {
      slots = List<String>.from(data['timeSlots']);
    } else if (data['jamMulai'] != null && data['jamSelesai'] != null) {
      slots = ['${data['jamMulai']} - ${data['jamSelesai']}'];
    }

    final parsedBatasWaktuBayar = (data['batasWaktuBayar'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(hours: 4));

    String currentStatus = data['status'] ?? BookingStatusHelper.menungguBayar;
    if (currentStatus == BookingStatusHelper.menungguBayar &&
        DateTime.now().isAfter(parsedBatasWaktuBayar)) {
      currentStatus = BookingStatusHelper.expired;
    }

    BookingModel model = BookingModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? 'LPK-${doc.id.substring(0, 8).toUpperCase()}',
      fieldId: data['fieldId'] ?? '',
      mitraId: data['mitraId'] ?? data['MitraId'] ?? data['id_pemilik'] ?? '',
      fieldName: data['fieldName'] ?? data['namaLapangan'] ?? '',
      fieldAddress: data['fieldAddress'] ?? '',
      fieldCategory: data['fieldCategory'] ?? '',
      fieldImageUrl: data['fieldImageUrl'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? data['namaPenyewa'] ?? '',
      userAvatarUrl: data['userAvatarUrl'],
      tanggal: (data['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlots: slots,
      durasi: data['durasi'] ?? slots.length,
      hargaLapangan: data['hargaLapangan'] ?? data['totalHarga'] ?? 0,
      biayaLayanan: data['biayaLayanan'] ?? 0,
      totalBayar: data['totalBayar'] ?? data['totalHarga'] ?? 0,
      metodePembayaran: data['metodePembayaran'] ?? '',
      status: currentStatus,
      snapToken: data['snapToken'],
      paymentUrl: data['paymentUrl'],
      paymentTransactionId: data['paymentTransactionId'],
      statusTimeline: data['statusTimeline'] != null
          ? List<Map<String, dynamic>>.from(data['statusTimeline'])
          : [
              {
                'status': currentStatus,
                'waktu': data['createdAt'] ?? Timestamp.now(),
              }
            ],
      batasWaktuBayar: parsedBatasWaktuBayar,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReviewed: data['isReviewed'] ?? false,
      isRescheduleRequested: data['isRescheduleRequested'] ?? false,
      rescheduleDate: (data['rescheduleDate'] as Timestamp?)?.toDate(),
      rescheduleTimeSlots: data['rescheduleTimeSlots'] != null
          ? List<String>.from(data['rescheduleTimeSlots'])
          : null,
      rescheduleReason: data['rescheduleReason'],
      rescheduleStatus: data['rescheduleStatus'],
    );

    if (model.isTicketExpired) {
      return model.copyWith(status: BookingStatusHelper.expired);
    }

    return model;
  }

  // ─── Method: toFirestore ──────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'fieldId': fieldId,
      'mitraId': mitraId,
      'fieldName': fieldName,
      'fieldAddress': fieldAddress,
      'fieldCategory': fieldCategory,
      'fieldImageUrl': fieldImageUrl,
      'userId': userId,
      'userName': userName,
      if (userAvatarUrl != null) 'userAvatarUrl': userAvatarUrl,
      'tanggal': Timestamp.fromDate(tanggal),
      'timeSlots': timeSlots,
      'durasi': durasi,
      'hargaLapangan': hargaLapangan,
      'biayaLayanan': biayaLayanan,
      'totalBayar': totalBayar,
      'metodePembayaran': metodePembayaran,
      'status': status,
      if (snapToken != null) 'snapToken': snapToken,
      if (paymentUrl != null) 'paymentUrl': paymentUrl,
      if (paymentTransactionId != null) 'paymentTransactionId': paymentTransactionId,
      'statusTimeline': statusTimeline,
      'batasWaktuBayar': Timestamp.fromDate(batasWaktuBayar),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isReviewed': isReviewed,
      'isRescheduleRequested': isRescheduleRequested,
      if (rescheduleDate != null) 'rescheduleDate': Timestamp.fromDate(rescheduleDate!),
      if (rescheduleTimeSlots != null) 'rescheduleTimeSlots': rescheduleTimeSlots,
      if (rescheduleReason != null) 'rescheduleReason': rescheduleReason,
      if (rescheduleStatus != null) 'rescheduleStatus': rescheduleStatus,
    };
  }

  // ─── Method: copyWith ─────────────────────────────────────────────────────

  /// Membuat salinan BookingModel dengan field yang diubah
  BookingModel copyWith({
    String? id,
    String? bookingId,
    String? fieldId,
    String? mitraId,
    String? fieldName,
    String? fieldAddress,
    String? fieldCategory,
    String? fieldImageUrl,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    DateTime? tanggal,
    List<String>? timeSlots,
    int? durasi,
    int? hargaLapangan,
    int? biayaLayanan,
    int? totalBayar,
    String? metodePembayaran,
    String? status,
    String? snapToken,
    String? paymentUrl,
    String? paymentTransactionId,
    List<Map<String, dynamic>>? statusTimeline,
    DateTime? batasWaktuBayar,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isReviewed,
    bool? isRescheduleRequested,
    DateTime? rescheduleDate,
    List<String>? rescheduleTimeSlots,
    String? rescheduleReason,
    String? rescheduleStatus,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      fieldId: fieldId ?? this.fieldId,
      mitraId: mitraId ?? this.mitraId,
      fieldName: fieldName ?? this.fieldName,
      fieldAddress: fieldAddress ?? this.fieldAddress,
      fieldCategory: fieldCategory ?? this.fieldCategory,
      fieldImageUrl: fieldImageUrl ?? this.fieldImageUrl,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      tanggal: tanggal ?? this.tanggal,
      timeSlots: timeSlots ?? this.timeSlots,
      durasi: durasi ?? this.durasi,
      hargaLapangan: hargaLapangan ?? this.hargaLapangan,
      biayaLayanan: biayaLayanan ?? this.biayaLayanan,
      totalBayar: totalBayar ?? this.totalBayar,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      status: status ?? this.status,
      snapToken: snapToken ?? this.snapToken,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      statusTimeline: statusTimeline ?? this.statusTimeline,
      batasWaktuBayar: batasWaktuBayar ?? this.batasWaktuBayar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReviewed: isReviewed ?? this.isReviewed,
      isRescheduleRequested: isRescheduleRequested ?? this.isRescheduleRequested,
      rescheduleDate: rescheduleDate ?? this.rescheduleDate,
      rescheduleTimeSlots: rescheduleTimeSlots ?? this.rescheduleTimeSlots,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      rescheduleStatus: rescheduleStatus ?? this.rescheduleStatus,
    );
  }

  @override
  String toString() => 'BookingModel(id: $id, bookingId: $bookingId, status: $status)';
}
