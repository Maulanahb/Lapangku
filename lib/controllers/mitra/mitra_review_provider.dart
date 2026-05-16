import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_review_model.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

class MitraReviewNotifier extends StateNotifier<AsyncValue<List<MitraReviewModel>>> {
  final MitraService _service;
  final String _mitraId;

  MitraReviewNotifier(this._service, this._mitraId) : super(const AsyncLoading()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    if (_mitraId.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    
    state = const AsyncLoading();
    try {
      final reviews = await _service.getReviews(_mitraId);
      state = AsyncData(reviews);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> replyReview({
    required String fieldId,
    required String reviewId,
    required String replyText,
  }) async {
    try {
      await _service.replyReview(
        fieldId: fieldId,
        reviewId: reviewId,
        replyText: replyText,
      );
      // Reload reviews to reflect changes
      await loadReviews();
    } catch (e) {
      rethrow;
    }
  }
}

final mitraReviewProvider = StateNotifierProvider<MitraReviewNotifier, AsyncValue<List<MitraReviewModel>>>((ref) {
  final service = ref.watch(mitraServiceProvider);
  final user = ref.watch(authProvider).user;
  final mitraId = user?.uid ?? '';
  return MitraReviewNotifier(service, mitraId);
});
