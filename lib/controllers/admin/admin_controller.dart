import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/admin/admin_field_model.dart';
import 'package:lapangku/models/admin/booking_model.dart';
import 'package:lapangku/models/admin/admin_stats.dart';
import 'package:lapangku/services/firebase/admin_service.dart';

// ─── Service Provider ─────────────────────────────────────────────────────

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

// ─── Stats ───────────────────────────────────────────────────────────────────

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

// ─── Bookings Per Hari (chart) ────────────────────────────────────────────────

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

// ─── All Users ────────────────────────────────────────────────────────────────

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
}

final allUsersProvider = StateNotifierProvider<AllUsersNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AllUsersNotifier(ref.watch(adminServiceProvider));
});

// ─── Fields ───────────────────────────────────────────────────────────────────

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
    required String fieldId,
    required String ownerUid,
    required String status,
  }) async {
    await _service.updateFieldVerifikasi(
      fieldId: fieldId,
      ownerUid: ownerUid,
      status: status,
    );
    await load();
  }
}

final adminFieldsProvider =
    StateNotifierProvider<AdminFieldsNotifier, AsyncValue<List<AdminFieldModel>>>((ref) {
  return AdminFieldsNotifier(ref.watch(adminServiceProvider));
});

// ─── Bookings ─────────────────────────────────────────────────────────────────

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
