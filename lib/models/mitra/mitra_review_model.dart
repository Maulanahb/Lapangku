import 'package:cloud_firestore/cloud_firestore.dart';

class MitraReviewModel {
  final String id;
  final String fieldId;
  final String fieldName;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int rating;
  final String comment;
  final DateTime date;
  final String? replyText;
  final DateTime? replyDate;
  final List<String> photoUrls;

  const MitraReviewModel({
    required this.id,
    required this.fieldId,
    required this.fieldName,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.date,
    this.replyText,
    this.replyDate,
    this.photoUrls = const [],
  });

  bool get isReplied => replyText != null && replyText!.isNotEmpty;

  factory MitraReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extract fieldId from path if not present in data
    String fieldId = data['fieldId'] ?? '';
    if (fieldId.isEmpty && doc.reference.parent.parent != null) {
      fieldId = doc.reference.parent.parent!.id;
    }

    return MitraReviewModel(
      id: doc.id,
      fieldId: fieldId,
      fieldName: data['fieldName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Customer',
      userPhotoUrl: data['userPhotoUrl'] ?? data['customerPhotoUrl'],
      rating: (data['rating'] ?? 0).toInt(),
      comment: data['comment'] ?? '',
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyText: data['replyText'],
      replyDate: (data['replyDate'] as Timestamp?)?.toDate(),
      photoUrls: (data['photoUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'fieldName': fieldName,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(date),
      'replyText': replyText,
      'replyDate': replyDate != null ? Timestamp.fromDate(replyDate!) : null,
      'photoUrls': photoUrls,
    };
  }

  MitraReviewModel copyWith({
    String? id,
    String? fieldId,
    String? fieldName,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    int? rating,
    String? comment,
    DateTime? date,
    String? replyText,
    DateTime? replyDate,
    List<String>? photoUrls,
  }) {
    return MitraReviewModel(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      fieldName: fieldName ?? this.fieldName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      replyText: replyText ?? this.replyText,
      replyDate: replyDate ?? this.replyDate,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}
