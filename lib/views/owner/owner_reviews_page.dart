import 'package:flutter/material.dart';

class OwnerReviewsPage extends StatelessWidget {
  const OwnerReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock reviews
    final List<Map<String, dynamic>> reviews = [
      {'user': 'Andi S.', 'rating': 5, 'comment': 'Lapangan bagus dan bersih, fasilitas lengkap.', 'date': '12 Okt 2026'},
      {'user': 'Budi P.', 'rating': 4, 'comment': 'Oke lah buat main bareng teman, cuma parkir agak sempit.', 'date': '10 Okt 2026'},
      {'user': 'Cakra W.', 'rating': 5, 'comment': 'Admin responsif, lapangan oke.', 'date': '08 Okt 2026'},
    ];
    // Uncomment below to test empty state:
    // final List<Map<String, dynamic>> reviews = [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Ulasan Pelanggan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: reviews.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline_rounded, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Belum ada ulasan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text('Ulasan dari pelanggan akan muncul di sini.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(review['user'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(review['date'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review['rating'] ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFB800),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(review['comment'], style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
