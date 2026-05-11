import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';

final _bookingSvcProvider =
    Provider<BookingService>((ref) => BookingService());

// ── Stream Provider: booking berdasarkan mitraId (langsung dari auth) ──
final MitraBookingStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);

  final service = ref.watch(_bookingSvcProvider);
  // Query langsung via mitraId — tidak perlu tunggu field provider load
  return service.streamMitraBookingsByMitraId(uid, statusFilter: statusFilter);
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
