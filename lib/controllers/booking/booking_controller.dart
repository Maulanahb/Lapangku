import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/services/firebase/booking_service.dart';
import 'package:lapangku/models/booking/booking_model.dart';

// Mengekspor lifecycle providers agar bisa diakses via file ini
export 'package:lapangku/controllers/booking/booking_lifecycle_provider.dart';

// --- SERVICE PROVIDER ---

// Provider utama untuk memanggil BookingService
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

// --- CUSTOMER PROVIDERS ---

// Memantau slot jadwal yang sudah dipesan secara real-time (berdasarkan ID lapangan & tanggal)
final bookedSlotsProvider = StreamProvider.autoDispose.family<List<String>, String>((ref, param) async* {
  final parts = param.split('|');
  final fieldId = parts[0];
  final date = DateTime.parse(parts[1]);
  final service = ref.watch(bookingServiceProvider);
  
  yield* service.streamBookedSlots(fieldId: fieldId, date: date);
});

// Mengambil daftar riwayat booking milik pelanggan tertentu (sekali ambil)
final userBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, userId) async {
  final service = ref.watch(bookingServiceProvider);
  return service.getUserBookings(userId);
});

// Memantau riwayat booking milik pelanggan secara real-time
final userBookingsStreamProvider =
    StreamProvider.autoDispose.family<List<BookingModel>, String>((ref, userId) {
  final service = ref.watch(bookingServiceProvider);
  return service.streamUserBookings(userId);
});

// Mengambil detail satu transaksi booking
final bookingDetailProvider =
    FutureProvider.family<BookingModel?, String>((ref, bookingId) async {
  final service = ref.watch(bookingServiceProvider);
  return service.getBookingById(bookingId);
});

// Memantau perubahan status detail booking secara real-time
final activeBookingStreamProvider =
    StreamProvider.autoDispose.family<BookingModel?, String>((ref, bookingId) {
  final service = ref.watch(bookingServiceProvider);
  return service.streamBooking(bookingId);
});

// --- MITRA PROVIDERS ---

// Memantau daftar booking yang masuk ke Mitra secara real-time (bisa di-filter berdasarkan status)
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

// --- ADMIN PROVIDERS ---

// Memantau seluruh transaksi booking di aplikasi secara real-time (untuk Dashboard Admin)
final adminAllBookingsStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  final service = ref.watch(bookingServiceProvider);
  return service.streamAllBookings(statusFilter: statusFilter);
});
