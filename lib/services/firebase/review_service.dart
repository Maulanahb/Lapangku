import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewServiceProvider = Provider((ref) => ReviewService());

final userReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final service = ref.watch(reviewServiceProvider);
  return await service.getUserReviews(userId);
});

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitReview({
    required String bookingId,
    required String fieldId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    final reviewRef = _db.collection('fields').doc(fieldId).collection('reviews').doc();
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((transaction) async {
      final fieldRef = _db.collection('fields').doc(fieldId);
      final fieldSnap = await transaction.get(fieldRef);

      if (!fieldSnap.exists) {
        throw Exception('Lapangan tidak ditemukan');
      }

      final data = fieldSnap.data()!;
      final currentAvg = (data['ratingAvg'] ?? 0.0) as num;
      final currentTotal = (data['totalUlasan'] ?? 0) as int;

      final newTotal = currentTotal + 1;
      final newAvg = ((currentAvg * currentTotal) + rating) / newTotal;

      transaction.update(fieldRef, {
        'ratingAvg': double.parse(newAvg.toStringAsFixed(1)),
        'totalUlasan': newTotal,
      });
      
      // Also update the review doc and booking doc within the same transaction to be safe?
      // No, batch and transaction shouldn't mix directly. Let's just do everything in the transaction!
      transaction.set(reviewRef, {
        'bookingId': bookingId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'fieldName': data['nama'] ?? data['namaLapangan'] ?? '',
        'fieldImageUrl': data['fotoUtama'] ?? data['fieldImageUrl'] ?? '',
      });
      transaction.update(bookingRef, {
        'isReviewed': true,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    final querySnapshot = await _db
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .get();

    final docs = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      
      // Also inject fieldId from the document path
      if (doc.reference.parent.parent != null) {
        data['fieldId'] = doc.reference.parent.parent!.id;
      }
      
      return data;
    }).toList();

    // Sort locally descending by createdAt to avoid needing a Firestore composite index
    docs.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return docs;
  }
}
