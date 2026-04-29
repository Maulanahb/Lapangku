import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/owner/booking/repositories/owner_booking_repository.dart';
import 'package:lapangku/features/owner/field/providers/owner_field_provider.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';

final _bookingSvcProvider =
    Provider<BookingService>((ref) => BookingService());

final ownerBookingRepositoryProvider = Provider<OwnerBookingRepository>(
    (ref) => OwnerBookingRepository(ref.watch(_bookingSvcProvider)));

// ── Stream Provider: booking berdasarkan lapangan owner ──────────
final ownerBookingStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  final fieldsAsync = ref.watch(ownerFieldProvider).fields;
  final fieldIds = fieldsAsync.value?.map((f) => f.id).toList() ?? [];
  final repo = ref.watch(ownerBookingRepositoryProvider);
  return repo.streamBookings(fieldIds, statusFilter: statusFilter);
});

// ── Mutating actions ───────────────────────────────────────────────
class OwnerBookingActionsNotifier extends StateNotifier<Set<String>> {
  final OwnerBookingRepository _repository;

  OwnerBookingActionsNotifier(this._repository) : super({});

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

final ownerBookingActionsProvider =
    StateNotifierProvider<OwnerBookingActionsNotifier, Set<String>>((ref) {
  final repo = ref.watch(ownerBookingRepositoryProvider);
  return OwnerBookingActionsNotifier(repo);
});
