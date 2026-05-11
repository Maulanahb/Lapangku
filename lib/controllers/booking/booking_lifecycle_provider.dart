import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/services/firebase/booking_lifecycle_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICE PROVIDER (Singleton)
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider tunggal untuk BookingLifecycleService.
/// Seluruh role (Customer, Mitra, Admin) menggunakan service yang sama.
final bookingLifecycleServiceProvider =
    Provider<BookingLifecycleService>((ref) {
  return BookingLifecycleService();
});

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOMER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Stream booking milik Customer tertentu (real-time per booking).
/// Usage: ref.watch(customerBookingStreamProvider('bookingDocId'))
final customerBookingStreamProvider =
    StreamProvider.family<BookingModel?, String>((ref, bookingId) {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.streamBooking(bookingId);
});

/// FutureProvider: semua booking milik Customer.
/// Usage: ref.watch(customerBookingsProvider('userId'))
final customerBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, userId) async {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.getUserBookings(userId);
});

/// FutureProvider: slot yang sudah dipesan untuk tanggal tertentu.
/// Parameter format: "fieldId|yyyy-MM-dd"
final customerBookedSlotsProvider =
    FutureProvider.family<List<String>, String>((ref, param) async {
  final parts = param.split('|');
  final fieldId = parts[0];
  final date = DateTime.parse(parts[1]);
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.getBookedSlots(fieldId: fieldId, date: date);
});

/// Notifier untuk aksi-aksi Customer (create, pay, cancel).
/// State: loading indicator + error tracking.
class CustomerBookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final BookingLifecycleService _service;

  CustomerBookingActionsNotifier(this._service)
      : super(const AsyncValue.data(null));

  /// Membuat booking baru.
  Future<BookingModel?> createBooking({
    required FieldModel field,
    required UserModel user,
    required DateTime date,
    required List<String> timeSlots,
    required String metodePembayaran,
    required int biayaLayanan,
  }) async {
    state = const AsyncValue.loading();
    try {
      final booking = await _service.createBooking(
        field: field,
        user: user,
        date: date,
        timeSlots: timeSlots,
        metodePembayaran: metodePembayaran,
        biayaLayanan: biayaLayanan,
      );
      state = const AsyncValue.data(null);
      return booking;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }

  /// Upload bukti bayar dummy (testing).
  Future<bool> uploadDummyPayment(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      await _service.uploadDummyPaymentProof(bookingId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  /// Konfirmasi pembayaran QRIS.
  Future<bool> confirmQris(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      await _service.confirmQrisPayment(bookingId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  /// Batalkan booking.
  Future<bool> cancelBooking(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      await _service.cancelBooking(bookingId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

final customerBookingActionsProvider =
    StateNotifierProvider<CustomerBookingActionsNotifier, AsyncValue<void>>(
        (ref) {
  return CustomerBookingActionsNotifier(
      ref.watch(bookingLifecycleServiceProvider));
});

// ═══════════════════════════════════════════════════════════════════════════════
// MITRA PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Stream semua booking milik Mitra (berdasarkan mitraId langsung).
/// Real-time — UI otomatis update saat Customer membuat booking baru.
///
/// Parameter format: "mitraId" atau "mitraId|statusFilter"
final mitraBookingsByIdStreamProvider =
    StreamProvider.family<List<BookingModel>, String>((ref, param) {
  final service = ref.watch(bookingLifecycleServiceProvider);
  final parts = param.split('|');
  final mitraId = parts[0];
  final statusFilter = parts.length > 1 ? parts[1] : null;
  return service.streamMitraBookingsByMitraId(
    mitraId,
    statusFilter: statusFilter,
  );
});

/// Stream booking menunggu konfirmasi khusus Mitra (shortcut).
/// UI: Badge notifikasi di dashboard Mitra.
final mitraPendingBookingsProvider =
    StreamProvider.family<List<BookingModel>, String>((ref, mitraId) {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.streamMitraBookingsByMitraId(
    mitraId,
    statusFilter: BookingStatusHelper.menungguKonfirmasi,
  );
});

/// Notifier untuk aksi Mitra (confirm/reject booking).
/// State: Set<String> berisi bookingId yang sedang diproses.
class MitraBookingLifecycleActionsNotifier extends StateNotifier<Set<String>> {
  final BookingLifecycleService _service;

  MitraBookingLifecycleActionsNotifier(this._service) : super({});

  /// Apakah booking tertentu sedang diproses?
  bool isProcessing(String bookingId) => state.contains(bookingId);

  /// [Mitra] Konfirmasi booking.
  Future<bool> confirmBooking(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.confirmBooking(bookingId);
      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.difference({bookingId});
    }
  }

  /// [Mitra] Tolak booking.
  Future<bool> rejectBooking(String bookingId, {String? reason}) async {
    state = {...state, bookingId};
    try {
      await _service.rejectBooking(bookingId, reason: reason);
      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.difference({bookingId});
    }
  }
}

final mitraBookingLifecycleActionsProvider =
    StateNotifierProvider<MitraBookingLifecycleActionsNotifier, Set<String>>(
        (ref) {
  return MitraBookingLifecycleActionsNotifier(
      ref.watch(bookingLifecycleServiceProvider));
});

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Stream seluruh booking (Admin monitoring).
/// Admin melihat semua booking dari semua Mitra & Customer.
///
/// Parameter (nullable): statusFilter. Null = semua status.
final adminAllBookingsStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.streamAllBookings(statusFilter: statusFilter);
});

/// FutureProvider: statistik booking (Admin dashboard).
final adminBookingStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.getBookingStats();
});

/// Notifier untuk aksi Admin (force update, auto-complete trigger).
class AdminBookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final BookingLifecycleService _service;

  AdminBookingActionsNotifier(this._service)
      : super(const AsyncValue.data(null));

  /// Force-update status booking (untuk kasus darurat).
  Future<bool> forceUpdateStatus(
    String bookingId, {
    required String newStatus,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.forceUpdateBookingStatus(
        bookingId,
        newStatus: newStatus,
        reason: reason,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  /// Trigger auto-complete untuk semua booking yang jam mainnya sudah lewat.
  Future<int> triggerAutoComplete() async {
    state = const AsyncValue.loading();
    try {
      final count = await _service.autoCompleteExpiredBookings();
      state = const AsyncValue.data(null);
      return count;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return 0;
    }
  }
}

final adminBookingActionsProvider =
    StateNotifierProvider<AdminBookingActionsNotifier, AsyncValue<void>>((ref) {
  return AdminBookingActionsNotifier(
      ref.watch(bookingLifecycleServiceProvider));
});
