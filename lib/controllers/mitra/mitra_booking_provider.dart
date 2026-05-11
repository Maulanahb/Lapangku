import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_field_provider.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';

final _bookingSvcProvider =
    Provider<BookingService>((ref) => BookingService());

// ── Stream Provider: booking berdasarkan lapangan Mitra ──────────
final MitraBookingStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  final fieldsAsync = ref.watch(mitraFieldProvider).fields;
  final fieldIds = fieldsAsync.value?.map((f) => f.id).toList() ?? [];
  final service = ref.watch(_bookingSvcProvider);
  return service.streamMitraBookings(fieldIds, statusFilter: statusFilter);
});

// ── Mutating actions ───────────────────────────────────────────────
class MitraBookingActionsNotifier extends StateNotifier<Set<String>> {
  final BookingService _service;

  MitraBookingActionsNotifier(this._service) : super({});

  Future<void> confirmBooking(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.confirmBooking(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    state = {...state, bookingId};
    try {
      await _service.rejectBooking(bookingId, reason: reason);
    } finally {
      state = state.difference({bookingId});
    }
  }

  bool isLoading(String bookingId) => state.contains(bookingId);
}

final MitraBookingActionsProvider =
    StateNotifierProvider<MitraBookingActionsNotifier, Set<String>>((ref) {
  final service = ref.watch(_bookingSvcProvider);
  return MitraBookingActionsNotifier(service);
});
