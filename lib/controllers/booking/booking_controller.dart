import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/services/firebase/booking_service.dart';

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
final userBookingsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final service = ref.watch(bookingServiceProvider);
  return service.getUserBookings(userId);
});
