import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/owner_review_model.dart';
import '../repositories/owner_review_repository.dart';

final ownerReviewRepositoryProvider = Provider((ref) => OwnerReviewRepository());

class OwnerReviewNotifier extends StateNotifier<AsyncValue<List<OwnerReviewModel>>> {
  final OwnerReviewRepository _repository;

  OwnerReviewNotifier(this._repository) : super(const AsyncLoading()) {
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

final ownerReviewProvider = StateNotifierProvider<OwnerReviewNotifier, AsyncValue<List<OwnerReviewModel>>>((ref) {
  final repository = ref.watch(ownerReviewRepositoryProvider);
  return OwnerReviewNotifier(repository);
});
