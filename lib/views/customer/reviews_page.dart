import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/services/firebase/review_service.dart';

class ReviewsPage extends ConsumerWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ulasan Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B6B3A),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text('Silakan login untuk melihat ulasan Anda')),
      );
    }

    final reviewsAsync = ref.watch(userReviewsProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Ulasan Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userReviewsProvider(user.uid)),
          ),
        ],
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
        error: (e, _) => Center(child: Text('Gagal memuat ulasan:\n$e')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Belum ada ulasan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  const SizedBox(height: 8),
                  const Text(
                    'Anda belum memberikan ulasan\nuntuk lapangan manapun.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF718096)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReviewCard(review: review);
            },
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] ?? 5) as int;
    final comment = (review['comment'] ?? '') as String;
    final fieldName = (review['fieldName'] ?? 'Lapangan') as String;
    final fieldImageUrl = (review['fieldImageUrl'] ?? '') as String;
    
    DateTime date = DateTime.now();
    if (review['createdAt'] != null) {
      // In getUserReviews we already converted to DateTime, but let's be safe
      if (review['createdAt'] is DateTime) {
        date = review['createdAt'] as DateTime;
      } else {
        date = review['createdAt'].toDate();
      }
    }
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field Info Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EC),
                  borderRadius: BorderRadius.circular(10),
                  image: fieldImageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(fieldImageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: fieldImageUrl.isEmpty
                    ? const Center(child: Icon(Icons.sports_soccer, color: Color(0xFF1B6B3A)))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fieldName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3748)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
              // Rating Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comment,
                style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
