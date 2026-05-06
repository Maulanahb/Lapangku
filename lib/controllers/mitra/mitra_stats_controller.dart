import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:intl/intl.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

/// Provider untuk mengambil semua booking milik mitra secara real-time
final mitraBookingsProvider = StreamProvider.family<List<BookingModel>, String>((ref, mitraId) {
  final bookingService = ref.watch(bookingServiceProvider);
  
  // Kita butuh fieldIds milik mitra ini dulu
  final fieldsAsync = ref.watch(mitraFieldProvider).fields;
  
  return fieldsAsync.when(
    data: (fields) {
      final fieldIds = fields.map((f) => f.id).toList();
      return bookingService.streamMitraBookings(fieldIds);
    },
    loading: () => const Stream.empty(),
    error: (e, s) => const Stream.empty(),
  );
});

/// Provider untuk pesanan yang menunggu konfirmasi (Waiting List)
final mitraWaitingBookingsProvider = Provider.family<List<BookingModel>, String>((ref, mitraId) {
  final bookingsAsync = ref.watch(mitraBookingsProvider(mitraId));
  return bookingsAsync.when(
    data: (bookings) => bookings.where((b) => b.status == 'menunggu_konfirmasi').toList(),
    loading: () => [],
    error: (e, s) => [],
  );
});

/// Provider untuk statistik hari ini (Jumlah Pesanan & Total Pendapatan)
final mitraTodayStatsProvider = Provider.family<Map<String, dynamic>, String>((ref, mitraId) {
  final bookingsAsync = ref.watch(mitraBookingsProvider(mitraId));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return bookingsAsync.when(
    data: (bookings) {
      final todayBookings = bookings.where((b) {
        final bDate = DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day);
        return bDate.isAtSameMomentAs(today);
      }).toList();

      final confirmedToday = todayBookings.where((b) => b.status == 'dikonfirmasi' || b.status == 'selesai').toList();
      
      int revenue = 0;
      for (var b in confirmedToday) {
        revenue += b.totalBayar;
      }

      return {
        'count': todayBookings.length,
        'revenue': revenue,
        'confirmedCount': confirmedToday.length,
      };
    },
    loading: () => {'count': 0, 'revenue': 0, 'confirmedCount': 0, 'isLoading': true},
    error: (e, s) => {'count': 0, 'revenue': 0, 'confirmedCount': 0, 'error': e},
  );
});

/// Provider untuk ringkasan pendapatan 7 hari terakhir
final mitraRevenueWeeklyProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, mitraId) {
  final bookingsAsync = ref.watch(mitraBookingsProvider(mitraId));
  
  return bookingsAsync.when(
    data: (bookings) {
      final now = DateTime.now();
      List<Map<String, dynamic>> weeklyData = [];
      
      // Loop 7 hari ke belakang
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayDate = DateTime(date.year, date.month, date.day);
        final dayName = DateFormat('EEE', 'id').format(dayDate); // Sen, Sel, ...

        final dayBookings = bookings.where((b) {
          final bDate = DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day);
          return bDate.isAtSameMomentAs(dayDate) && (b.status == 'dikonfirmasi' || b.status == 'selesai');
        });

        int dayRevenue = 0;
        for (var b in dayBookings) {
          dayRevenue += b.totalBayar;
        }

        weeklyData.add({
          'day': dayName,
          'revenue': dayRevenue,
          'isToday': i == 0,
        });
      }
      return weeklyData;
    },
    loading: () => [],
    error: (e, s) => [],
  );
});
