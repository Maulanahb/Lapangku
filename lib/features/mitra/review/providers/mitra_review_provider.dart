import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mitra_review_model.dart';
import '../repositories/mitra_review_repository.dart';

final MitraReviewRepositoryProvider = Provider((ref) => MitraReviewRepository());

class MitraReviewNotifier extends StateNotifier<AsyncValue<List<MitraReviewModel>>> {
  final MitraReviewRepository _repository;

  MitraReviewNotifier(this._repository) : super(const AsyncLoading()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    state = const AsyncLoading();
    try {
      final reviews = await _repository.getReviews();
      state = AsyncData(reviews);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final mitraReviewProvider = StateNotifierProvider<MitraReviewNotifier, AsyncValue<List<MitraReviewModel>>>((ref) {
  final repository = ref.watch(MitraReviewRepositoryProvider);
  return MitraReviewNotifier(repository);
});
