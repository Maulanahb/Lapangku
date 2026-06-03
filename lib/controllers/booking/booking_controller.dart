import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/services/firebase/booking_service.dart';
import 'package:lapangku/models/booking/booking_model.dart';

// Re-export lifecycle providers agar bisa diakses via booking_controller.dart
export 'package:lapangku/controllers/booking/booking_lifecycle_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider tunggal untuk BookingService.
/// Digunakan oleh semua role (Customer, Mitra, Admin).
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOMER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// [Customer] FutureProvider: slot yang sudah dipesan untuk tanggal tertentu.
/// Parameter format: "fieldId|yyyy-MM-dd"
/// Usage: ref.watch(bookedSlotsProvider('fieldId123|2026-05-11'))
final bookedSlotsProvider =
    FutureProvider.family<List<String>, String>((ref, param) async {
  final parts = param.split('|');
  final fieldId = parts[0];
  final date = DateTime.parse(parts[1]);
  final service = ref.watch(bookingServiceProvider);
  return service.getBookedSlots(fieldId: fieldId, date: date);
});

/// [Customer] FutureProvider: semua booking milik user tertentu.
/// Usage: ref.watch(userBookingsProvider('userId123'))
final userBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, userId) async {
  final service = ref.watch(bookingServiceProvider);
  return service.getUserBookings(userId);
});

/// [Customer] StreamProvider: semua booking milik user tertentu secara real-time.
/// Usage: ref.watch(userBookingsStreamProvider('userId123'))
final userBookingsStreamProvider =
    StreamProvider.autoDispose.family<List<BookingModel>, String>((ref, userId) {
  final service = ref.watch(bookingServiceProvider);
  return service.streamUserBookings(userId);
});

/// [Customer] FutureProvider: detail booking tunggal.
/// Usage: ref.watch(bookingDetailProvider('bookingDocId'))
final bookingDetailProvider =
    FutureProvider.family<BookingModel?, String>((ref, bookingId) async {
  final service = ref.watch(bookingServiceProvider);
  return service.getBookingById(bookingId);
});

/// [Customer] StreamProvider: memonitor perubahan booking tunggal secara real-time.
/// Dipakai di halaman detail booking agar status selalu up-to-date.
/// Usage: ref.watch(activeBookingStreamProvider('bookingDocId'))
final activeBookingStreamProvider =
    StreamProvider.autoDispose.family<BookingModel?, String>((ref, bookingId) {
  final service = ref.watch(bookingServiceProvider);
  return service.streamBooking(bookingId);
});

// ═══════════════════════════════════════════════════════════════════════════════
// MITRA PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// [Mitra] StreamProvider: semua booking milik Mitra berdasarkan mitraId.
/// Real-time — UI otomatis update saat Customer membuat booking baru.
///
/// Parameter format: "mitraId" atau "mitraId|statusFilter"
/// Usage: ref.watch(mitraBookingsStreamProvider('mitraId123'))
///        ref.watch(mitraBookingsStreamProvider('mitraId123|menunggu_konfirmasi'))
final mitraBookingsStreamProvider =
    StreamProvider.family<List<BookingModel>, String>((ref, param) {
  final service = ref.watch(bookingServiceProvider);
  final parts = param.split('|');
  final mitraId = parts[0];
  final statusFilter = parts.length > 1 ? parts[1] : null;
  return service.streamMitraBookingsByMitraId(
    mitraId,
    statusFilter: statusFilter,
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// [Admin] StreamProvider: seluruh booking dari semua Mitra & Customer.
/// Digunakan untuk dashboard Admin monitoring real-time.
///
/// Parameter (nullable): statusFilter. Null = semua status.
/// Usage: ref.watch(adminAllBookingsStreamProvider(null))
///        ref.watch(adminAllBookingsStreamProvider('menunggu_konfirmasi'))
final adminAllBookingsStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  final service = ref.watch(bookingServiceProvider);
  return service.streamAllBookings(statusFilter: statusFilter);
});
