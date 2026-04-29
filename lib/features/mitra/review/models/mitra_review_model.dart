class MitraReviewModel {
  final String id;
  final String userName;
  final int rating;
  final String comment;
  final DateTime date;

  const MitraReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
