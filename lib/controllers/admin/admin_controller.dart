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
// â”€â”€â”€ Service Provider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

// â”€â”€â”€ Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€â”€ Bookings Per Hari (chart) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€â”€ All Users â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AllUsersNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AdminService _service;

  AllUsersNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final users = await _service.getAllUsers();
      state = AsyncValue.data(users);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateVerifikasi(String uid, String status) async {
    await _service.updateUserVerifikasi(uid, status);
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

// â”€â”€â”€ Fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AdminFieldsNotifier extends StateNotifier<AsyncValue<List<AdminFieldModel>>> {
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
      fieldId: '', // Tetap panggil service, tapi fieldId kosong karena verifikasi mitra
    );
    await load();
  }
}

final adminFieldsProvider =
    StateNotifierProvider<AdminFieldsNotifier, AsyncValue<List<AdminFieldModel>>>((ref) {
  return AdminFieldsNotifier(ref.watch(adminServiceProvider));
});

// â”€â”€â”€ Bookings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class BookingsNotifier
    extends StateNotifier<AsyncValue<List<BookingModel>>> {
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
// â”€â”€â”€ Recent Activities â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ActivitiesNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
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

final activitiesProvider = StateNotifierProvider<ActivitiesNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ActivitiesNotifier(ref.watch(adminServiceProvider));
});

// ─── NEW REQUIREMENTS ────────────────────────────────────────────────────────

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

final adminAllBookingsProvider = StreamProvider<List<global_booking.BookingModel>>((ref) {
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
    return snapshot.docs.map((doc) {
      final data = doc.data();
      String status = (data['statusVerifikasi'] ?? 'menunggu').toString().toLowerCase().trim();
      if (!data.containsKey('statusVerifikasi')) {
        status = (data['isVerified'] == true) ? 'aktif' : 'menunggu';
      }
      return AdminFieldModel(
        fieldId: doc.id,
        mitraId: doc.id,
        namaLapangan: data['businessName'] ?? data['namaBisnis'] ?? 'Bisnis Baru',
        namaMitra: data['MitraName'] ?? data['ownerName'] ?? 'Mitra',
        emailPemilik: data['email'] ?? '',
        lokasi: data['alamat'] ?? 'Alamat belum diatur',
        hargaPerJam: 0,
        jenis: data['sport'] ?? data['jenisLapangan'] ?? '',
        statusVerifikasi: status,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        photoUrls: (data['photoUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        phone: data['phone'] ?? '',
        deskripsi: data['deskripsi'] ?? '',
        tipeLapangan: data['tipeLapangan'] ?? '',
        fasilitas: (data['fasilitas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? (data['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        jamOperasional: data['jamOperasional'] ?? '',
        hariOperasional: (data['hariOperasional'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        ktpUrl: data['ktpUrl'],
        selfieUrl: data['selfieUrl'],
      );
    }).toList();
  });
});

final adminAllUsersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirestoreService.instance.collection('users').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()).toList();
  });
});

class AdminDashboardStats {
  final int totalPengguna;
  final int totalMitra;
  final int totalBookingHariIni;
  final int totalPendapatan;

  AdminDashboardStats({
    required this.totalPengguna,
    required this.totalMitra,
    required this.totalBookingHariIni,
    required this.totalPendapatan,
  });
}

final adminDashboardStatsProvider = Provider<AdminDashboardStats>((ref) {
  final bookingsAsync = ref.watch(adminAllBookingsProvider);
  final mitrasAsync = ref.watch(adminAllMitrasProvider);
  final usersAsync = ref.watch(adminAllUsersStreamProvider);

  int totalPengguna = 0;
  int totalMitra = 0;
  int totalBookingHariIni = 0;
  int totalPendapatan = 0;

  if (usersAsync.hasValue) {
    totalPengguna = usersAsync.value!.length;
  }

  if (mitrasAsync.hasValue) {
    totalMitra = mitrasAsync.value!.length;
  }

  if (bookingsAsync.hasValue) {
    final now = DateTime.now();
    for (var b in bookingsAsync.value!) {
      if (b.status == 'selesai') {
        // Sama dengan laporan analistik: gunakan totalBayar (= totalHarga)
        totalPendapatan += b.totalBayar;
      }

      if (b.tanggal.year == now.year && b.tanggal.month == now.month && b.tanggal.day == now.day) {
        totalBookingHariIni++;
      }
    }
  }

  return AdminDashboardStats(
    totalPengguna: totalPengguna,
    totalMitra: totalMitra,
    totalBookingHariIni: totalBookingHariIni,
    totalPendapatan: totalPendapatan,
  );
});

final adminPayoutsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamAllPayouts();
});
