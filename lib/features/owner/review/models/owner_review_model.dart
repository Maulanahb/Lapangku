class OwnerReviewModel {
  final String id;
  final String userName;
  final int rating;
  final String comment;
  final DateTime date;

  const OwnerReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
