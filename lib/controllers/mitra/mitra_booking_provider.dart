import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/services/firebase/booking_service.dart';

// Service provider untuk koneksi ke backend Booking
final _bookingSvcProvider =
    Provider<BookingService>((ref) => BookingService());

// Stream data booking khusus untuk Mitra yang sedang login
final MitraBookingStreamProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, statusFilter) {
  
  // Pantau status login agar data otomatis update
  final user = ref.watch(authStateProvider).value;
  final uid = user?.uid ?? '';
  
  if (uid.isEmpty) return Stream.value([]);

  final service = ref.watch(_bookingSvcProvider);
  
  // Ambil data langsung dari service berdasarkan mitraId
  return service.streamMitraBookingsByMitraId(uid, statusFilter: statusFilter);
});

// --- Aksi-aksi State Booking ---
class MitraBookingActionsNotifier extends StateNotifier<Set<String>> {
  final BookingService _service;
  final String _mitraId;

  MitraBookingActionsNotifier(this._service, this._mitraId) : super({});

  // Konfirmasi booking yang masuk dari pelanggan
  Future<void> confirmBooking(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.confirmBooking(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  // Tolak booking dari pelanggan beserta alasannya
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    state = {...state, bookingId};
    try {
      await _service.rejectBooking(bookingId, reason: reason);
    } finally {
      state = state.difference({bookingId});
    }
  }

  // Setujui permintaan pemindahan jadwal (reschedule)
  Future<void> approveReschedule(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.approveReschedule(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  // Tolak permintaan pemindahan jadwal (reschedule)
  Future<void> rejectReschedule(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.rejectReschedule(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  // Mengecek apakah suatu proses booking sedang loading
  bool isLoading(String bookingId) => state.contains(bookingId);

  // Validasi e-ticket saat pelanggan melakukan scan QR di lapangan
  Future<BookingModel> validateTicket(String bookingId) async {
    state = {...state, bookingId};
    try {
      if (_mitraId.isEmpty) throw Exception('Anda belum login.');
      return await _service.validateAndCompleteBooking(bookingId, _mitraId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  // Menyembunyikan riwayat booking dari daftar Mitra
  Future<void> hideBooking(String bookingId) async {
    state = {...state, bookingId};
    try {
      await _service.hideBookingForMitra(bookingId);
    } finally {
      state = state.difference({bookingId});
    }
  }

  // Membuat booking manual secara offline (misal ada yang pesan lewat telepon) untuk memblokir jadwal
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

// Provider utama untuk memanggil aksi-aksi state booking di atas
final MitraBookingActionsProvider =
    StateNotifierProvider<MitraBookingActionsNotifier, Set<String>>((ref) {
  final service = ref.watch(_bookingSvcProvider);
  final uid = ref.watch(currentUidProvider);
  return MitraBookingActionsNotifier(service, uid);
});

