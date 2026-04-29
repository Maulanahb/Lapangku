import 'owner_review_model.dart';

class OwnerReviewRepository {
  Future<List<OwnerReviewModel>> getReviews() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API
    
    return [
      OwnerReviewModel(id: '1', userName: 'Andi S.', rating: 5, comment: 'Lapangan bagus dan bersih.', date: DateTime(2026, 10, 12)),
      OwnerReviewModel(id: '2', userName: 'Budi P.', rating: 4, comment: 'Oke lah buat main bareng.', date: DateTime(2026, 10, 10)),
    ];
  }
}
