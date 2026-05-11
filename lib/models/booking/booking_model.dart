import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper untuk validasi transisi status booking.
///
/// Tidak bisa menggunakan nama 'BookingStatus' karena sudah ada enum
/// di `standards/models/booking_status.dart`.
///
/// Flow: menunggu_bayar → menunggu_konfirmasi → dikonfirmasi → selesai
///       menunggu_bayar → expired / dibatalkan
///       menunggu_konfirmasi → ditolak / dibatalkan
class BookingStatusHelper {
  BookingStatusHelper._();

  // String constants untuk Firestore values
  static const String menungguBayar = 'menunggu_bayar';
  static const String menungguKonfirmasi = 'menunggu_konfirmasi';
  static const String dikonfirmasi = 'dikonfirmasi';
  static const String selesai = 'selesai';
  static const String dibatalkan = 'dibatalkan';
  static const String ditolak = 'ditolak';
  static const String expired = 'expired';

  /// Status yang dianggap "aktif" (memblokir slot waktu)
  static const List<String> activeStatuses = [
    menungguBayar,
    menungguKonfirmasi,
    dikonfirmasi,
  ];

  /// Status yang dianggap "selesai" (terminal state)
  static const List<String> terminalStatuses = [
    selesai,
    dibatalkan,
    ditolak,
    expired,
  ];

  /// Cek apakah transisi status valid
  static bool isValidTransition(String from, String to) {
    final validTransitions = <String, List<String>>{
      menungguBayar: [menungguKonfirmasi, expired, dibatalkan],
      menungguKonfirmasi: [dikonfirmasi, ditolak, dibatalkan],
      dikonfirmasi: [selesai],
    };
    return validTransitions[from]?.contains(to) ?? false;
  }
}

class BookingModel {
  final String id;
  final String bookingId; // LPK-YYYYMMDD-XXX
  final String fieldId;
  final String mitraId; // ← BARU: ID pemilik lapangan untuk query langsung
  final String fieldName;
  final String fieldAddress;
  final String fieldCategory;
  final String fieldImageUrl;
  final String userId;
  final String userName;
  final DateTime tanggal;
  final List<String> timeSlots; // ["19:00 - 20:00", "20:00 - 21:00"]
  final int durasi; // in hours
  final int hargaLapangan;
  final int biayaLayanan;
  final int totalBayar;
  final String metodePembayaran;
  final String? buktiTransferUrl;
  final String status; // menunggu_bayar, menunggu_konfirmasi, dikonfirmasi, selesai, dibatalkan, ditolak, expired
  final String? alasanPenolakan; // ← BARU: alasan jika ditolak oleh Mitra
  final List<Map<String, dynamic>> statusTimeline; // [{status: 'menunggu_bayar', waktu: Timestamp}]
  final DateTime batasWaktuBayar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isReviewed;

  const BookingModel({
    required this.id,
    required this.bookingId,
    required this.fieldId,
    this.mitraId = '',
    required this.fieldName,
    required this.fieldAddress,
    required this.fieldCategory,
    required this.fieldImageUrl,
    required this.userId,
    required this.userName,
    required this.tanggal,
    required this.timeSlots,
    required this.durasi,
    required this.hargaLapangan,
    required this.biayaLayanan,
    required this.totalBayar,
    required this.metodePembayaran,
    this.buktiTransferUrl,
    required this.status,
    this.alasanPenolakan,
    required this.statusTimeline,
    required this.batasWaktuBayar,
    required this.createdAt,
    required this.updatedAt,
    this.isReviewed = false,
  });

  /// Apakah booking masih aktif (memblokir slot)
  bool get isActive => BookingStatusHelper.activeStatuses.contains(status);

  /// Apakah booking sudah di terminal state
  bool get isTerminal => BookingStatusHelper.terminalStatuses.contains(status);

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse timeSlots properly
    List<String> slots = [];
    if (data['timeSlots'] != null) {
      slots = List<String>.from(data['timeSlots']);
    } else if (data['jamMulai'] != null && data['jamSelesai'] != null) {
      // Fallback for old data
      slots = ['${data['jamMulai']} - ${data['jamSelesai']}'];
    }

    return BookingModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? 'LPK-${doc.id.substring(0, 8).toUpperCase()}',
      fieldId: data['fieldId'] ?? '',
      mitraId: data['mitraId'] ?? '',
      fieldName: data['fieldName'] ?? data['namaLapangan'] ?? '',
      fieldAddress: data['fieldAddress'] ?? '',
      fieldCategory: data['fieldCategory'] ?? '',
      fieldImageUrl: data['fieldImageUrl'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? data['namaPenyewa'] ?? '',
      tanggal: (data['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlots: slots,
      durasi: data['durasi'] ?? slots.length,
      hargaLapangan: data['hargaLapangan'] ?? data['totalHarga'] ?? 0,
      biayaLayanan: data['biayaLayanan'] ?? 0,
      totalBayar: data['totalBayar'] ?? data['totalHarga'] ?? 0,
      metodePembayaran: data['metodePembayaran'] ?? '',
      buktiTransferUrl: data['buktiTransferUrl'],
      status: data['status'] ?? 'menunggu_bayar',
      alasanPenolakan: data['alasanPenolakan'],
      statusTimeline: data['statusTimeline'] != null 
          ? List<Map<String, dynamic>>.from(data['statusTimeline'])
          : [
              {'status': data['status'] ?? 'menunggu_bayar', 'waktu': data['createdAt'] ?? Timestamp.now()}
            ],
      batasWaktuBayar: (data['batasWaktuBayar'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 4)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReviewed: data['isReviewed'] ?? false,
    );
  }

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
      'tanggal': Timestamp.fromDate(tanggal),
      'timeSlots': timeSlots,
      'durasi': durasi,
      'hargaLapangan': hargaLapangan,
      'biayaLayanan': biayaLayanan,
      'totalBayar': totalBayar,
      'metodePembayaran': metodePembayaran,
      'buktiTransferUrl': buktiTransferUrl,
      'status': status,
      'alasanPenolakan': alasanPenolakan,
      'statusTimeline': statusTimeline,
      'batasWaktuBayar': Timestamp.fromDate(batasWaktuBayar),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isReviewed': isReviewed,
    };
  }

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
    DateTime? tanggal,
    List<String>? timeSlots,
    int? durasi,
    int? hargaLapangan,
    int? biayaLayanan,
    int? totalBayar,
    String? metodePembayaran,
    String? buktiTransferUrl,
    String? status,
    String? alasanPenolakan,
    List<Map<String, dynamic>>? statusTimeline,
    DateTime? batasWaktuBayar,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isReviewed,
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
      tanggal: tanggal ?? this.tanggal,
      timeSlots: timeSlots ?? this.timeSlots,
      durasi: durasi ?? this.durasi,
      hargaLapangan: hargaLapangan ?? this.hargaLapangan,
      biayaLayanan: biayaLayanan ?? this.biayaLayanan,
      totalBayar: totalBayar ?? this.totalBayar,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      buktiTransferUrl: buktiTransferUrl ?? this.buktiTransferUrl,
      status: status ?? this.status,
      alasanPenolakan: alasanPenolakan ?? this.alasanPenolakan,
      statusTimeline: statusTimeline ?? this.statusTimeline,
      batasWaktuBayar: batasWaktuBayar ?? this.batasWaktuBayar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }
}
