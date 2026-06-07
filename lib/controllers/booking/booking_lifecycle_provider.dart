import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/services/firebase/booking_lifecycle_service.dart';

// --- SERVICE PROVIDER ---

// Provider utama untuk memanggil BookingLifecycleService (digunakan oleh semua role)
final bookingLifecycleServiceProvider =
    Provider<BookingLifecycleService>((ref) {
  return BookingLifecycleService();
});

// --- CUSTOMER PROVIDERS ---

// Memantau status satu pesanan milik Customer secara real-time
final customerBookingStreamProvider =
    StreamProvider.family<BookingModel?, String>((ref, bookingId) {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.streamBooking(bookingId);
});

// Mengambil seluruh riwayat pesanan milik Customer
final customerBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, userId) async {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.getUserBookings(userId);
});

// Mengambil daftar jam yang sudah dibooking pada tanggal tertentu
final customerBookedSlotsProvider =
    FutureProvider.family<List<String>, String>((ref, param) async {
  final parts = param.split('|');
  final fieldId = parts[0];
  final date = DateTime.parse(parts[1]);
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.getBookedSlots(fieldId: fieldId, date: date);
});

// Controller untuk aksi transaksi Customer (Buat, Bayar, Batal)
class CustomerBookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final BookingLifecycleService _service;

  CustomerBookingActionsNotifier(this._service)
      : super(const AsyncValue.data(null));

  // Membuat pesanan (booking) baru
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

  // Membatalkan pesanan
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

// --- MITRA PROVIDERS ---

// Memantau pesanan yang masuk ke Mitra secara real-time (bisa di-filter)
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

// Memantau khusus pesanan yang sedang menunggu pembayaran (untuk notifikasi Mitra)
final mitraPendingBookingsProvider =
    StreamProvider.family<List<BookingModel>, String>((ref, mitraId) {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.streamMitraBookingsByMitraId(
    mitraId,
    statusFilter: BookingStatusHelper.menungguBayar,
  );
});

// Controller untuk aksi Mitra (Konfirmasi / Tolak pesanan)
class MitraBookingLifecycleActionsNotifier extends StateNotifier<Set<String>> {
  final BookingLifecycleService _service;

  MitraBookingLifecycleActionsNotifier(this._service) : super({});

  // Cek apakah pesanan sedang loading diproses
  bool isProcessing(String bookingId) => state.contains(bookingId);

  // Mitra mengkonfirmasi pesanan
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

  // Mitra menolak pesanan
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

// --- ADMIN PROVIDERS ---

// Memantau seluruh pesanan di aplikasi secara real-time (Dashboard Admin)
final adminAllBookingsStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.streamAllBookings(statusFilter: statusFilter);
});

// Mengambil statistik transaksi untuk Dashboard Admin
final adminBookingStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(bookingLifecycleServiceProvider);
  return service.getBookingStats();
});

// Controller untuk aksi Admin (Ubah status paksa & Auto-complete)
class AdminBookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final BookingLifecycleService _service;

  AdminBookingActionsNotifier(this._service)
      : super(const AsyncValue.data(null));

  // Mengubah status pesanan secara paksa (darurat)
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

  // Menyelesaikan otomatis pesanan yang jam mainnya sudah berlalu
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
