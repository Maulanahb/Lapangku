import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String bookingId; // LPK-YYYYMMDD-XXX
  final String fieldId;
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
  final String status; // menunggu_bayar, menunggu_konfirmasi, dikonfirmasi, selesai, dibatalkan
  final List<Map<String, dynamic>> statusTimeline; // [{status: 'menunggu_bayar', waktu: Timestamp}]
  final DateTime batasWaktuBayar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.bookingId,
    required this.fieldId,
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
    required this.statusTimeline,
    required this.batasWaktuBayar,
    required this.createdAt,
    required this.updatedAt,
  });

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
      statusTimeline: data['statusTimeline'] != null 
          ? List<Map<String, dynamic>>.from(data['statusTimeline'])
          : [
              {'status': data['status'] ?? 'menunggu_bayar', 'waktu': data['createdAt'] ?? Timestamp.now()}
            ],
      batasWaktuBayar: (data['batasWaktuBayar'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 4)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'fieldId': fieldId,
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
      'statusTimeline': statusTimeline,
      'batasWaktuBayar': Timestamp.fromDate(batasWaktuBayar),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
