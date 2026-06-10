import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/services/firebase/booking_service.dart';
import 'package:lapangku/models/booking/booking_model.dart' as global_booking;
import 'package:lapangku/models/field/field_model.dart';

import 'package:lapangku/models/admin/admin_field_model.dart';
import 'package:lapangku/models/admin/booking_model.dart';
import 'package:lapangku/models/admin/admin_stats.dart';
import 'package:lapangku/services/firebase/admin_service.dart';

// --- Service Provider ---
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

// --- Statistik Admin ---

// Controller untuk mengambil dan menyimpan statistik admin (total user, transaksi, dll)
class AdminStatsNotifier extends StateNotifier<AsyncValue<AdminStats>> {
  final AdminService _service;

  AdminStatsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _service.getStats();
      state = AsyncValue.data(stats);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final adminStatsProvider =
    StateNotifierProvider<AdminStatsNotifier, AsyncValue<AdminStats>>((ref) {
  return AdminStatsNotifier(ref.watch(adminServiceProvider));
});

// --- Grafik Transaksi Harian ---

// Controller untuk mengambil data grafik transaksi per hari
class BookingsChartNotifier extends StateNotifier<AsyncValue<List<int>>> {
  final AdminService _service;

  BookingsChartNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.getBookingsPerHari();
      state = AsyncValue.data(data);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final bookingsChartProvider =
    StateNotifierProvider<BookingsChartNotifier, AsyncValue<List<int>>>((ref) {
  return BookingsChartNotifier(ref.watch(adminServiceProvider));
});

// --- Manajemen Pengguna ---

// Controller untuk mengambil daftar pengguna dengan sistem paginasi (agar tidak berat)
class AllUsersNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AdminService _service;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  AllUsersNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    _lastDoc = null;
    _hasMore = true;
    _isLoadingMore = false;

    try {
      final snap = await _service.getUsersPaginatedRaw(limit: 20);
      if (snap.docs.length < 20) _hasMore = false;
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;

      final users = snap.docs
          .map((d) => <String, dynamic>{
                'uid': d.id,
                ...(d.data()! as Map<String, dynamic>)
              })
          .toList();
      state = AsyncValue.data(users);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is AsyncLoading) return;

    final currentList = state.value ?? [];
    _isLoadingMore = true;

    try {
      final snap =
          await _service.getUsersPaginatedRaw(limit: 20, startAfter: _lastDoc);
      if (snap.docs.length < 20) _hasMore = false;
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;

      final newUsers = snap.docs
          .map((d) => <String, dynamic>{
                'uid': d.id,
                ...(d.data()! as Map<String, dynamic>)
              })
          .toList();
      state = AsyncValue.data([...currentList, ...newUsers]);
    } catch (e) {
      debugPrint('Error loadMore: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> updateVerifikasi(String uid, String status) async {
    await _service.updateUserVerifikasi(uid, status);
    // Reload data if needed, or simply let the local state update. For PBL, reload is safer.
    await load();
  }

  Future<void> addUser(Map<String, dynamic> data) async {
    await _service.addUser(data);
    await load();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _service.updateUserData(uid, data);
    await load();
  }

  Future<void> deleteUser(String uid) async {
    await _service.deleteUser(uid);
    await load();
  }
}

final allUsersProvider = StateNotifierProvider<AllUsersNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AllUsersNotifier(ref.watch(adminServiceProvider));
});

// --- Manajemen Lapangan ---

// Controller untuk mengambil seluruh daftar lapangan untuk keperluan Admin
class AdminFieldsNotifier
    extends StateNotifier<AsyncValue<List<AdminFieldModel>>> {
  final AdminService _service;

  AdminFieldsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final fields = await _service.getAllFields();
      state = AsyncValue.data(fields);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateVerifikasi({
    required String mitraId,
    required String status,
  }) async {
    await _service.updateFieldVerifikasi(
      mitraId: mitraId,
      status: status,
      fieldId:
          '', // Tetap panggil service, tapi fieldId kosong karena verifikasi mitra
    );
    await load();
  }
}

final adminFieldsProvider = StateNotifierProvider<AdminFieldsNotifier,
    AsyncValue<List<AdminFieldModel>>>((ref) {
  return AdminFieldsNotifier(ref.watch(adminServiceProvider));
});

// --- Manajemen Transaksi ---

// Controller untuk mengambil semua data riwayat transaksi
class BookingsNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  final AdminService _service;

  BookingsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final bookings = await _service.getAllBookings();
      state = AsyncValue.data(bookings);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingModel>>>(
        (ref) {
  return BookingsNotifier(ref.watch(adminServiceProvider));
});

// --- Aktivitas Terbaru ---
// Controller untuk memantau aktivitas terbaru secara langsung
class ActivitiesNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AdminService _service;

  ActivitiesNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final activities = await _service.getRecentActivities();
      state = AsyncValue.data(activities);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final activitiesProvider = StateNotifierProvider<ActivitiesNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ActivitiesNotifier(ref.watch(adminServiceProvider));
});

// --- Provider Tambahan ---

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

final adminAllBookingsProvider =
    StreamProvider<List<global_booking.BookingModel>>((ref) {
  return ref.watch(bookingServiceProvider).streamAllBookings();
});

final adminAllFieldsProvider = StreamProvider<List<FieldModel>>((ref) {
  return FirestoreService.instance
      .collection('lapangan')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => FieldModel.fromFirestore(doc)).toList();
  });
});

final adminAllMitrasProvider = StreamProvider<List<AdminFieldModel>>((ref) {
  return FirestoreService.instance
      .collection('mitra')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map(AdminFieldModel.fromMitraDoc).toList();
  });
});

final adminAllUsersStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirestoreService.instance
      .collection('users')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()).toList();
  });
});

// Struktur data untuk Statistik Dashboard Admin
class AdminDashboardStats {
  final int totalPengguna;
  final int totalMitra;
  final int totalBookingHariIni;
  final int totalPendapatan;

  // Status counts for the donut/pie chart
  final int countSelesai;
  final int countMenungguBayar;
  final int countMenungguKonfirmasi;
  final int countDikonfirmasi;
  final int countDibatalkan;

  AdminDashboardStats({
    required this.totalPengguna,
    required this.totalMitra,
    required this.totalBookingHariIni,
    required this.totalPendapatan,
    required this.countSelesai,
    required this.countMenungguBayar,
    required this.countMenungguKonfirmasi,
    required this.countDikonfirmasi,
    required this.countDibatalkan,
  });
}

final adminDashboardStatsProvider =
    Provider<AsyncValue<AdminDashboardStats>>((ref) {
  final statsAsync = ref.watch(adminStatsProvider);
  return statsAsync.whenData((stats) => AdminDashboardStats(
        totalPengguna: stats.totalUsers,
        totalMitra: stats.lapanganAktif,
        totalBookingHariIni: stats.pesananHariIni,
        totalPendapatan: stats.totalPendapatan,
        countSelesai: stats.countSelesai,
        countMenungguBayar: stats.countMenungguBayar,
        countMenungguKonfirmasi: stats.countMenungguKonfirmasi,
        countDikonfirmasi: stats.countDikonfirmasi,
        countDibatalkan: stats.countDibatalkan,
      ));
});

// Provider untuk memantau riwayat penarikan saldo (payout) Mitra
final adminPayoutsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamAllPayouts();
});
