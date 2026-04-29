import 'Mitra_review_model.dart';

class MitraReviewRepository {
  Future<List<MitraReviewModel>> getReviews() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API
    
    return [
      MitraReviewModel(id: '1', userName: 'Andi S.', rating: 5, comment: 'Lapangan bagus dan bersih.', date: DateTime(2026, 10, 12)),
      MitraReviewModel(id: '2', userName: 'Budi P.', rating: 4, comment: 'Oke lah buat main bareng.', date: DateTime(2026, 10, 10)),
    ];
  }
}
