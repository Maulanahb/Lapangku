import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewServiceProvider = Provider((ref) => ReviewService());

final userReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  ref.keepAlive();
  final service = ref.watch(reviewServiceProvider);
  return service.getUserReviews(userId);
});

final fieldReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, fieldId) async {
  ref.keepAlive();
  final service = ref.watch(reviewServiceProvider);
  return service.getFieldReviews(fieldId);
});

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'lapangku-db',
  );

  Future<void> submitReview({
    required String bookingId,
    required String fieldId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
    String? userPhotoUrl,
    String? reviewImageUrl,
  }) async {
    // 1. Memastikan dokumen ulasan masuk ke SUB-KOLEKSI dari lapangan terkait
    final reviewRef = _db.collection('lapangan').doc(fieldId).collection('reviews').doc();
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((transaction) async {
      final fieldRef = _db.collection('lapangan').doc(fieldId);
      final fieldSnap = await transaction.get(fieldRef);

      if (!fieldSnap.exists) {
        throw Exception('Lapangan tidak ditemukan');
      }

      final data = fieldSnap.data()!;
      final currentAvg = (data['avg_rating'] ?? data['ratingAvg'] ?? 0.0) as num;
      final currentTotal = (data['total_ulasan'] ?? data['totalUlasan'] ?? 0) as int;
      final mitraId = data['mitraId'] ?? data['MitraId'] ?? data['id_pemilik'] ?? '';

      final newTotal = currentTotal + 1;
      final newAvg = ((currentAvg * currentTotal) + rating) / newTotal;

      // Update akumulasi rating di dokumen lapangan utama
      transaction.update(fieldRef, {
        'avg_rating': double.parse(newAvg.toStringAsFixed(1)),
        'total_ulasan': newTotal,
      });
      
      // Simpan data ulasan ke sub-koleksi dengan field 'userId' yang konsisten untuk Firebase Rules
      transaction.set(reviewRef, {
        'bookingId': bookingId,
        'fieldId': fieldId,
        'mitraId': mitraId,
        'userId': userId, // Digunakan untuk memvalidasi kepemilikan ulasan di Firebase Rules
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'reviewImageUrl': reviewImageUrl,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'fieldName': data['nama_lapangan'] ?? data['nama'] ?? data['namaLapangan'] ?? '',
        'fieldImageUrl': data['foto_lapangan'] != null && (data['foto_lapangan'] as List).isNotEmpty 
            ? (data['foto_lapangan'] as List).first 
            : data['fotoUtama'] ?? data['fieldImageUrl'] ?? '',
      });

      transaction.update(bookingRef, {
        'isReviewed': true,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    // Menggunakan collectionGroup karena ulasan tersebar di dalam sub-koleksi lapangan yang berbeda-beda
    final querySnapshot = await _db
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .get();

    final docs = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      
      if (doc.reference.parent.parent != null) {
        data['fieldId'] = doc.reference.parent.parent!.id;
      }
      
      return data;
    }).toList();

    docs.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return docs;
  }

  Future<List<Map<String, dynamic>>> getFieldReviews(String fieldId) async {
    final querySnapshot = await _db
        .collection('lapangan')
        .doc(fieldId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Menyisipkan ID dokumen asli agar bisa dipakai saat memanggil aksi Hapus
      return data;
    }).toList();
  }

  Future<void> deleteReview({
    required String fieldId,
    required String reviewId,
    required int rating,
    String? bookingId,
  }) async {
    // Validasi parameter untuk menghindari kegagalan query transaksi
    if (fieldId.isEmpty || reviewId.isEmpty) {
      throw Exception('ID Lapangan atau ID Ulasan tidak boleh kosong');
    }

    final reviewRef = _db.collection('lapangan').doc(fieldId).collection('reviews').doc(reviewId);
    final fieldRef = _db.collection('lapangan').doc(fieldId);

    await _db.runTransaction((transaction) async {
      final fieldSnap = await transaction.get(fieldRef);

      if (fieldSnap.exists) {
        final data = fieldSnap.data()!;
        final currentAvg = (data['avg_rating'] ?? data['ratingAvg'] ?? 0.0) as num;
        final currentTotal = (data['total_ulasan'] ?? data['totalUlasan'] ?? 0) as int;

        final newTotal = currentTotal - 1;
        final newAvg = newTotal > 0 ? ((currentAvg * currentTotal) - rating) / newTotal : 0.0;

        transaction.update(fieldRef, {
          'avg_rating': double.parse(newAvg.toStringAsFixed(1)),
          'total_ulasan': newTotal < 0 ? 0 : newTotal,
        });
      }

      // Jalankan proses penghapusan dokumen ulasan dari sub-koleksi
      transaction.delete(reviewRef);

      // Kembalikan status booking menjadi belum di-review agar customer bisa menulis ulang
      if (bookingId != null && bookingId.isNotEmpty) {
        final bookingRef = _db.collection('bookings').doc(bookingId);
        transaction.update(bookingRef, {'isReviewed': false});
      }
    });
  }
}