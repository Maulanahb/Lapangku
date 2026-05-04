import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_review_model.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

class MitraReviewNotifier extends StateNotifier<AsyncValue<List<MitraReviewModel>>> {
  final MitraService _service;

  MitraReviewNotifier(this._service) : super(const AsyncLoading()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    state = const AsyncLoading();
    try {
      final reviews = await _service.getReviews();
      state = AsyncData(reviews);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final mitraReviewProvider = StateNotifierProvider<MitraReviewNotifier, AsyncValue<List<MitraReviewModel>>>((ref) {
  final service = ref.watch(mitraServiceProvider);
  return MitraReviewNotifier(service);
});
