import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';

final _bookingSvcProvider =
    Provider<BookingService>((ref) => BookingService());

// ── Stream Provider: booking berdasarkan mitraId (langsung dari auth) ──
final MitraBookingStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  // Watch authStateProvider agar provider ini otomatis refresh saat login/logout
  final user = ref.watch(authStateProvider).value;
  final uid = user?.uid ?? '';
  
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

  Future<void> approveReschedule(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.approveReschedule(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  Future<void> rejectReschedule(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.rejectReschedule(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  bool isLoading(String bookingId) => state.contains(bookingId);

  /// Validasi E-Ticket via QR scan — returns BookingModel jika sukses
  Future<BookingModel> validateTicket(String bookingId) async {
    state = {...state, bookingId};
    try {
      final mitraId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (mitraId.isEmpty) throw Exception('Anda belum login.');
      return await _service.validateAndCompleteBooking(bookingId, mitraId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.deleteBooking(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  /// Buat booking offline (manual) untuk memblokir slot.
  Future<BookingModel> createOfflineBooking({
    required MitraFieldModel field,
    required String mitraId,
    required DateTime date,
    required List<String> timeSlots,
    required String namaPenyewa,
    String catatan = '',
  }) async {
    return _service.createOfflineBooking(
      fieldId: field.id,
      mitraId: mitraId,
      fieldName: field.namaVenue.isNotEmpty
          ? '${field.namaVenue} - ${field.namaLapangan}'
          : field.namaLapangan,
      fieldAddress: field.alamat,
      fieldCategory: field.jenisLapangan,
      fieldImageUrl: field.photoUrls.isNotEmpty ? field.photoUrls.first : '',
      date: date,
      timeSlots: timeSlots,
      hargaPerJam: field.hargaPerJam,
      namaPenyewa: namaPenyewa,
      catatan: catatan,
    );
  }
}

final MitraBookingActionsProvider =
    StateNotifierProvider<MitraBookingActionsNotifier, Set<String>>((ref) {
  final service = ref.watch(_bookingSvcProvider);
  return MitraBookingActionsNotifier(service);
});
