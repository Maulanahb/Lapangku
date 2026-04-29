import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/mitra/booking/repositories/mitra_booking_repository.dart';
import 'package:lapangku/features/mitra/field/providers/mitra_field_provider.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';

final _bookingSvcProvider =
    Provider<BookingService>((ref) => BookingService());

final MitraBookingRepositoryProvider = Provider<MitraBookingRepository>(
    (ref) => MitraBookingRepository(ref.watch(_bookingSvcProvider)));

// ── Stream Provider: booking berdasarkan lapangan Mitra ──────────
final MitraBookingStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  final fieldsAsync = ref.watch(mitraFieldProvider).fields;
  final fieldIds = fieldsAsync.value?.map((f) => f.id).toList() ?? [];
  final repo = ref.watch(MitraBookingRepositoryProvider);
  return repo.streamBookings(fieldIds, statusFilter: statusFilter);
});

// ── Mutating actions ───────────────────────────────────────────────
class MitraBookingActionsNotifier extends StateNotifier<Set<String>> {
  final MitraBookingRepository _repository;

  MitraBookingActionsNotifier(this._repository) : super({});

  Future<void> confirmBooking(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _repository.confirmBooking(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    state = {...state, bookingId};
    try {
      await _repository.rejectBooking(bookingId, reason: reason);
    } finally {
      state = state.difference({bookingId});
    }
  }

  bool isLoading(String bookingId) => state.contains(bookingId);
}

final MitraBookingActionsProvider =
    StateNotifierProvider<MitraBookingActionsNotifier, Set<String>>((ref) {
  final repo = ref.watch(MitraBookingRepositoryProvider);
  return MitraBookingActionsNotifier(repo);
});
