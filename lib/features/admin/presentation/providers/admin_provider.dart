import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/field_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/admin_repository.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(AdminRemoteDatasource());
});

// ─── Stats ───────────────────────────────────────────────────────────────────

class AdminStatsNotifier extends StateNotifier<AsyncValue<AdminStats>> {
  final AdminRepository _repo;

  AdminStatsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repo.getStats();
      state = AsyncValue.data(stats);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final adminStatsProvider =
    StateNotifierProvider<AdminStatsNotifier, AsyncValue<AdminStats>>((ref) {
  return AdminStatsNotifier(ref.watch(adminRepositoryProvider));
});

// ─── Bookings Per Hari (chart) ────────────────────────────────────────────────

class BookingsChartNotifier extends StateNotifier<AsyncValue<List<int>>> {
  final AdminRepository _repo;

  BookingsChartNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getBookingsPerHari();
      state = AsyncValue.data(data);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final bookingsChartProvider =
    StateNotifierProvider<BookingsChartNotifier, AsyncValue<List<int>>>((ref) {
  return BookingsChartNotifier(ref.watch(adminRepositoryProvider));
});

// ─── All Users ────────────────────────────────────────────────────────────────

class AllUsersNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AdminRepository _repo;

  AllUsersNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final users = await _repo.getAllUsers();
      state = AsyncValue.data(users);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateVerifikasi(String uid, String status) async {
    await _repo.updateUserVerifikasi(uid, status);
    await load();
  }
}

final allUsersProvider = StateNotifierProvider<AllUsersNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AllUsersNotifier(ref.watch(adminRepositoryProvider));
});

// ─── Fields ───────────────────────────────────────────────────────────────────

class FieldsNotifier extends StateNotifier<AsyncValue<List<FieldEntity>>> {
  final AdminRepository _repo;

  FieldsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final fields = await _repo.getAllFields();
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
    await _repo.updateFieldVerifikasi(
      fieldId: fieldId,
      ownerUid: ownerUid,
      status: status,
    );
    await load();
  }
}

final fieldsProvider =
    StateNotifierProvider<FieldsNotifier, AsyncValue<List<FieldEntity>>>((ref) {
  return FieldsNotifier(ref.watch(adminRepositoryProvider));
});

// ─── Bookings ─────────────────────────────────────────────────────────────────

class BookingsNotifier
    extends StateNotifier<AsyncValue<List<BookingEntity>>> {
  final AdminRepository _repo;

  BookingsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final bookings = await _repo.getAllBookings();
      state = AsyncValue.data(bookings);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingEntity>>>(
        (ref) {
  return BookingsNotifier(ref.watch(adminRepositoryProvider));
});