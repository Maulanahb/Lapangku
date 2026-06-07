import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_review_model.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// StreamProvider — auto-listen ke perubahan review secara realtime.
///
/// Saat customer menambah, mengedit, atau menghapus review,
/// Firestore snapshot akan otomatis mengirim data terbaru
/// tanpa perlu refresh manual dari halaman mitra.
final mitraReviewStreamProvider =
    StreamProvider<List<MitraReviewModel>>((ref) {
  final service = ref.watch(mitraServiceProvider);
  final mitraId = FirebaseAuth.instance.currentUser?.uid ?? '';
  return service.streamReviews(mitraId);
});

/// Provider untuk aksi reply review (write-only).
///
/// Karena data review sudah di-stream secara realtime,
/// setelah reply berhasil disimpan ke Firestore,
/// StreamProvider akan otomatis menerima update terbaru
/// tanpa perlu memanggil loadReviews() ulang.
final mitraReviewActionsProvider = Provider<MitraService>((ref) {
  return ref.watch(mitraServiceProvider);
});
