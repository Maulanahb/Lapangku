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
        jenis: '',
        statusVerifikasi: status,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  });
});

class AdminDashboardStats {
  final int totalBookingSelesai;
  final int totalPendapatan;
  final int totalLapangan;

  AdminDashboardStats({
    required this.totalBookingSelesai,
    required this.totalPendapatan,
    required this.totalLapangan,
  });
}

final adminDashboardStatsProvider = Provider<AdminDashboardStats>((ref) {
  final bookingsAsync = ref.watch(adminAllBookingsProvider);
  final fieldsAsync = ref.watch(adminAllFieldsProvider);

  int totalBookingSelesai = 0;
  int totalPendapatan = 0;
  int totalLapangan = 0;

  if (bookingsAsync.hasValue) {
    for (var b in bookingsAsync.value!) {
      if (b.status == 'selesai') {
        totalBookingSelesai++;
        totalPendapatan += b.biayaLayanan;
      }
    }
  }

  if (fieldsAsync.hasValue) {
    totalLapangan = fieldsAsync.value!.length;
  }

  return AdminDashboardStats(
    totalBookingSelesai: totalBookingSelesai,
    totalPendapatan: totalPendapatan,
    totalLapangan: totalLapangan,
  );
});

final adminPayoutsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamAllPayouts();
});
