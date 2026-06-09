import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';
import 'package:intl/intl.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

/// Enum untuk filter statistik
enum StatsFilter { hariIni, mingguIni, bulanIni, tahunIni }

/// Provider untuk menyimpan state filter aktif
final statsFilterProvider =
    StateProvider<StatsFilter>((ref) => StatsFilter.bulanIni);

/// Provider untuk mengambil semua booking milik mitra secara real-time
final mitraBookingsProvider =
    StreamProvider.family<List<BookingModel>, String>((ref, mitraId) {
  final bookingService = ref.watch(bookingServiceProvider);

  if (mitraId.isEmpty) return Stream.value([]);
  return bookingService.streamMitraBookingsByMitraId(mitraId);
});

/// Provider untuk pesanan terbaru (Recent Bookings)
final mitraRecentBookingsProvider =
    Provider.family<List<BookingModel>, String>((ref, mitraId) {
  final bookingsAsync = ref.watch(mitraBookingsProvider(mitraId));
  return bookingsAsync.when(
    data: (bookings) => bookings.take(5).toList(),
    loading: () => [],
    error: (e, s) => [],
  );
});

/// Provider untuk statistik hari ini (Jumlah Pesanan & Total Pendapatan)
final mitraTodayStatsProvider =
    Provider.family<Map<String, dynamic>, String>((ref, mitraId) {
  final bookingsAsync = ref.watch(mitraBookingsProvider(mitraId));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return bookingsAsync.when(
    data: (bookings) {
      final todayBookings = bookings.where((b) {
        final bDate = DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day);
        return bDate.isAtSameMomentAs(today);
      }).toList();

      final finishedToday = todayBookings
          .where((b) => b.status == 'selesai' || b.status == 'dikonfirmasi')
          .toList();

      int revenue = 0;
      for (var b in finishedToday) {
        revenue += b.totalBayar;
      }

      final confirmedToday = todayBookings
          .where((b) => b.status == 'dikonfirmasi')
          .toList();

      final waitingToday = todayBookings
          .where((b) =>
              b.status == 'menunggu_bayar' ||
              (b.isRescheduleRequested && b.rescheduleStatus == 'pending'))
          .toList();

      return {
        'count': todayBookings.length,
        'revenue': revenue,
        'confirmedCount': confirmedToday.length,
        'waitingCount': waitingToday.length,
      };
    },
    loading: () => {
      'count': 0,
      'revenue': 0,
      'confirmedCount': 0,
      'waitingCount': 0,
      'isLoading': true
    },
    error: (e, s) => {
      'count': 0,
      'revenue': 0,
      'confirmedCount': 0,
      'waitingCount': 0,
      'error': e
    },
  );
});

/// Provider untuk statistik bulan ini
final mitraMonthlyStatsProvider =
    Provider.family<Map<String, dynamic>, String>((ref, mitraId) {
  final bookingsAsync = ref.watch(mitraBookingsProvider(mitraId));
  final now = DateTime.now();

  return bookingsAsync.when(
    data: (bookings) {
      final monthBookings = bookings.where((b) {
        return b.createdAt.year == now.year && b.createdAt.month == now.month;
      }).toList();

      final finishedMonth = monthBookings
          .where((b) => b.status == 'selesai' || b.status == 'dikonfirmasi')
          .toList();

      int revenue = 0;
      for (var b in finishedMonth) {
        revenue += b.totalBayar;
      }

      final confirmedMonth = monthBookings
          .where((b) => b.status == 'dikonfirmasi' || b.status == 'selesai')
          .toList();

      return {
        'totalBookings': monthBookings.length,
        'confirmedBookings': confirmedMonth.length,
        'revenue': revenue,
      };
    },
    loading: () => {'totalBookings': 0, 'confirmedBookings': 0, 'revenue': 0},
    error: (e, s) => {'totalBookings': 0, 'confirmedBookings': 0, 'revenue': 0},
  );
});

/// Provider Statistik Lanjutan untuk Dashboard Statistik Booking
final mitraAdvancedStatsProvider =
    Provider.family<Map<String, dynamic>, String>((ref, mitraId) {
  final bookingsAsync = ref.watch(mitraBookingsProvider(mitraId));
  final filter = ref.watch(statsFilterProvider);

  return bookingsAsync.when(
    data: (bookings) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (kDebugMode) {
        debugPrint('DEBUG: mitraId: $mitraId');
        debugPrint('DEBUG: Total bookings fetched: ${bookings.length}');
        debugPrint('DEBUG: Filter type: $filter');
      }

      // 1. Filter bookings berdasarkan range waktu
      List<BookingModel> filteredBookings = bookings.where((b) {
        final bDate = DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day);

        switch (filter) {
          case StatsFilter.hariIni:
            return bDate.isAtSameMomentAs(today);
          case StatsFilter.mingguIni:
            final startOfWeek =
                today.subtract(Duration(days: today.weekday - 1));
            return bDate
                .isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
          case StatsFilter.bulanIni:
            return bDate.year == now.year && bDate.month == now.month;
          case StatsFilter.tahunIni:
            return bDate.year == now.year;
        }
      }).toList();

      if (kDebugMode) debugPrint('DEBUG: Filtered bookings count: ${filteredBookings.length}');

      // 2. Hitung Total Berhasil (Hero Card)
      final totalSuccess =
          filteredBookings.where((b) => b.status == 'selesai').length;

      // 3. Hitung Statistik Hari Ini (Info Row)
      final countToday = bookings.where((b) {
        final bDate = DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day);
        return bDate.isAtSameMomentAs(today);
      }).length;

      // 4. Hitung Kehadiran (Selesai vs Total Konfirmasi/Selesai/Batal)
      final relevantForAttendance = filteredBookings
          .where((b) => [
                'selesai',
                'dikonfirmasi',
                'dibatalkan',
                'ditolak',
                'expired'
              ].contains(b.status))
          .length;
      final attendanceRate = relevantForAttendance > 0
          ? (filteredBookings.where((b) => b.status == 'selesai').length /
                  relevantForAttendance *
                  100)
              .round()
          : 0;

      // 5. Cari Jam Teramai (Berdasarkan slot pertama)
      Map<String, int> hourCounts = {};
      for (var b in filteredBookings) {
        if (b.timeSlots.isNotEmpty) {
          final startHour = b.timeSlots.first.split(' - ').first;
          hourCounts[startHour] = (hourCounts[startHour] ?? 0) + 1;
        }
      }
      String peakHour = "00:00";
      int maxPeak = 0;
      hourCounts.forEach((hour, count) {
        if (count > maxPeak) {
          maxPeak = count;
          peakHour = hour;
        }
      });

      // 6. Grid Stats
      final activeCount = filteredBookings
          .where((b) =>
              b.status == 'dikonfirmasi' || b.status == 'menunggu_konfirmasi')
          .length;
      final cancelledCount = filteredBookings
          .where((b) =>
              b.status == 'dibatalkan' ||
              b.status == 'ditolak' ||
              b.status == 'expired')
          .length;

      // 7. Aktivitas Mingguan (7 Hari Terakhir) — data dari seluruh booking
      List<Map<String, dynamic>> weeklyData = [];
      int maxDayCount = 0;
      String peakDayName = '';
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayDate = DateTime(date.year, date.month, date.day);
        final dayName = DateFormat('EEE', 'id')
            .format(dayDate)
            .toUpperCase(); // SEN, SEL, ...

        final dayCount = bookings.where((b) {
          final bDate =
              DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day);
          return bDate.isAtSameMomentAs(dayDate) &&
              (b.status == 'selesai' || b.status == 'dikonfirmasi');
        }).length;

        // Lacak hari dengan booking terbanyak
        if (dayCount > maxDayCount) {
          maxDayCount = dayCount;
          peakDayName = DateFormat('EEEE', 'id').format(dayDate); // Senin, Selasa, dst
        }

        weeklyData.add({
          'day': dayName,
          'count': dayCount,
        });
      }

      // Tandai bar chart hari dengan booking terbanyak (isPeak)
      for (var data in weeklyData) {
        data['isPeak'] = data['count'] == maxDayCount && maxDayCount > 0;
      }

      // Buat insight text dinamis berdasarkan hari tersibuk
      String peakDayInsight = maxDayCount > 0
          ? 'Booking paling ramai terjadi pada $peakDayName ($maxDayCount booking).'
          : 'Belum ada data aktivitas minggu ini.';

      // 8. Slot Jam Terpopuler (Top 3)
      Map<String, int> slotMap = {};
      for (var b in filteredBookings) {
        for (var slot in b.timeSlots) {
          slotMap[slot] = (slotMap[slot] ?? 0) + 1;
        }
      }
      var sortedSlots = slotMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      List<Map<String, dynamic>> popularSlots = [];
      for (int i = 0; i < 3 && i < sortedSlots.length; i++) {
        popularSlots.add({
          'slot': sortedSlots[i].key,
          'percentage': (sortedSlots[i].value /
                  (filteredBookings.length.clamp(1, 100000)) *
                  100)
              .round(),
        });
      }
      // Fill empty slots if less than 3
      while (popularSlots.length < 3) {
        popularSlots.add({'slot': '-', 'percentage': 0});
      }

      // 9. Lapangan Paling Aktif — termasuk imageUrl dari data booking
      Map<String, int> fieldMap = {};
      for (var b in filteredBookings) {
        fieldMap[b.fieldName] = (fieldMap[b.fieldName] ?? 0) + 1;
      }
      String topField = "-";
      int topFieldCount = 0;
      fieldMap.forEach((name, count) {
        if (count > topFieldCount) {
          topFieldCount = count;
          topField = name;
        }
      });

      // Cari imageUrl dari booking terakhir milik lapangan paling aktif
      String topFieldImageUrl = '';
      if (topField != '-') {
        final topFieldBooking = filteredBookings
            .where((b) => b.fieldName == topField)
            .toList();
        if (topFieldBooking.isNotEmpty) {
          topFieldImageUrl = topFieldBooking.first.fieldImageUrl;
        }
      }

      // 10. Hitung Growth Rate (perbandingan periode saat ini vs sebelumnya)
      String growthStr = _calculateGrowth(bookings, filter, now);

      return {
        'totalSuccess': totalSuccess,
        'growth': growthStr,
        'todayCount': countToday,
        'attendanceRate': attendanceRate,
        'peakHour': peakHour,
        'activeCount': activeCount,
        'finishedCount': totalSuccess,
        'cancelledCount': cancelledCount,
        'weeklyActivity': weeklyData,
        'peakDayInsight': peakDayInsight,
        'popularSlots': popularSlots,
        'mostActiveField': {
          'name': topField,
          'count': topFieldCount,
          'badge': 'PALING RAMAI',
          'imageUrl': topFieldImageUrl,
        },
        'filteredCount': filteredBookings
            .length, // FIX: return filtered count for empty check
      };
    },
    loading: () => {'isLoading': true},
    error: (e, s) => {'error': e.toString()},
  );
});

/// Menghitung persentase growth dengan membandingkan jumlah booking
/// "selesai" pada periode saat ini vs periode sebelumnya yang sama panjang.
String _calculateGrowth(
    List<BookingModel> allBookings, StatsFilter filter, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  DateTime currentStart;
  DateTime previousStart;
  DateTime previousEnd;

  switch (filter) {
    case StatsFilter.hariIni:
      currentStart = today;
      previousStart = today.subtract(const Duration(days: 1));
      previousEnd = today;
      break;
    case StatsFilter.mingguIni:
      currentStart = today.subtract(Duration(days: today.weekday - 1));
      previousStart = currentStart.subtract(const Duration(days: 7));
      previousEnd = currentStart;
      break;
    case StatsFilter.bulanIni:
      currentStart = DateTime(now.year, now.month, 1);
      previousStart = DateTime(now.year, now.month - 1, 1);
      previousEnd = currentStart;
      break;
    case StatsFilter.tahunIni:
      currentStart = DateTime(now.year, 1, 1);
      previousStart = DateTime(now.year - 1, 1, 1);
      previousEnd = currentStart;
      break;
  }

  final currentCount = allBookings.where((b) {
    final bDate = DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day);
    return b.status == 'selesai' &&
        !bDate.isBefore(currentStart) &&
        !bDate.isAfter(today);
  }).length;

  final previousCount = allBookings.where((b) {
    final bDate = DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day);
    return b.status == 'selesai' &&
        !bDate.isBefore(previousStart) &&
        bDate.isBefore(previousEnd);
  }).length;

  if (previousCount == 0 && currentCount == 0) return '+0%';
  if (previousCount == 0) return '+100%';

  final growthPercent =
      ((currentCount - previousCount) / previousCount * 100).round();
  return growthPercent >= 0 ? '+$growthPercent%' : '$growthPercent%';
}

/// Provider untuk ringkasan pendapatan 7 hari terakhir (tetap dipertahankan jika ada yang pakai)
final mitraRevenueWeeklyProvider =
    Provider.family<List<Map<String, dynamic>>, String>((ref, mitraId) {
  final bookingsAsync = ref.watch(mitraBookingsProvider(mitraId));

  return bookingsAsync.when(
    data: (bookings) {
      final now = DateTime.now();
      List<Map<String, dynamic>> weeklyData = [];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayDate = DateTime(date.year, date.month, date.day);
        final dayName = DateFormat('EEE', 'id').format(dayDate);

        final dayBookings = bookings.where((b) {
          final bDate =
              DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day);
          return bDate.isAtSameMomentAs(dayDate) && 
                 (b.status == 'selesai' || b.status == 'dikonfirmasi');
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
