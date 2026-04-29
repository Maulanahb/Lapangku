import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';

class OwnerBookingRepository {
  final BookingService _service;

  OwnerBookingRepository(this._service);

  Stream<List<BookingModel>> streamBookings(
    List<String> fieldIds, {
    String? statusFilter,
  }) =>
      _service.streamOwnerBookings(fieldIds, statusFilter: statusFilter);

  Future<void> confirmBooking(String bookingId) =>
      _service.confirmBooking(bookingId);

  Future<void> rejectBooking(String bookingId, {String? reason}) =>
      _service.rejectBooking(bookingId, reason: reason);
}
