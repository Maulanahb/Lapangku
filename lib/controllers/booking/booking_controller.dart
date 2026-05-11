import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/services/firebase/booking_service.dart';
import 'package:lapangku/models/booking/booking_model.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

/// Provider untuk mengambil slot yang sudah dibooking
/// Parameter: fieldId + tanggal dalam format "fieldId|yyyy-MM-dd"
final bookedSlotsProvider = FutureProvider.family<List<String>, String>((ref, param) async {
  final parts = param.split('|');
  final fieldId = parts[0];
  final date = DateTime.parse(parts[1]);
  final service = ref.watch(bookingServiceProvider);
  return service.getBookedSlots(fieldId: fieldId, date: date);
});

/// Provider untuk mengambil semua booking milik user
final userBookingsProvider = FutureProvider.family<List<BookingModel>, String>((ref, userId) async {
  final service = ref.watch(bookingServiceProvider);
  return service.getUserBookings(userId);
});

/// Provider untuk mengambil detail booking tunggal
final bookingDetailProvider = FutureProvider.family<BookingModel?, String>((ref, bookingId) async {
  final service = ref.watch(bookingServiceProvider);
  return service.getBookingById(bookingId);
});

/// Stream provider untuk memonitor perubahan pada booking tunggal secara real-time
final activeBookingStreamProvider = StreamProvider.family<BookingModel?, String>((ref, bookingId) {
  final service = ref.watch(bookingServiceProvider);
  return service.streamBooking(bookingId);
});
