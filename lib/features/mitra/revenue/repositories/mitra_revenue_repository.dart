import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/features/mitra/revenue/models/mitra_revenue_model.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

class MitraRevenueRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MitraService _mitraService;

  MitraRevenueRepository(this._mitraService);

  Future<MitraRevenueModel> getRevenue(String MitraId, DateTime startDate, DateTime endDate) async {
    final fields = await _mitraService.getMitraFields(MitraId);
    if (fields.isEmpty) {
      return const MitraRevenueModel(totalRevenue: 0, totalOrders: 0, transactions: []);
    }
    
    final fieldIds = fields.map((e) => e.id).toList();
    
    final startTimestamp = Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day));
    final endTimestamp = Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));

    List<BookingModel> allBookings = [];
    
    for (int i = 0; i < fieldIds.length; i += 30) {
      final chunk = fieldIds.sublist(i, i + 30 > fieldIds.length ? fieldIds.length : i + 30);
      final snap = await _db
          .collection('bookings')
          .where('fieldId', whereIn: chunk)
          .where('tanggal', isGreaterThanOrEqualTo: startTimestamp)
          .where('tanggal', isLessThanOrEqualTo: endTimestamp)
          .get();
          
      allBookings.addAll(snap.docs.map((d) => BookingModel.fromFirestore(d)));
    }
    
    final validBookings = allBookings.where((b) => 
       b.status == 'dikonfirmasi' || b.status == 'selesai'
    ).toList();
    
    int totalRevenue = 0;
    List<MitraTransactionModel> transactions = [];
    
    for (var b in validBookings) {
      totalRevenue += b.totalBayar;
      transactions.add(MitraTransactionModel(
        id: b.id,
        customerName: b.userName,
        fieldName: b.fieldName,
        amount: b.totalBayar,
        date: b.tanggal,
      ));
    }
    
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    return MitraRevenueModel(
      totalRevenue: totalRevenue,
      totalOrders: validBookings.length,
      transactions: transactions,
    );
  }
}
