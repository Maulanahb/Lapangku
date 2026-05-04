import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tentang LapangKu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // App Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B6B3A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_soccer,
                size: 80,
                color: Color(0xFF1B6B3A),
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'LapangKu',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B6B3A),
              ),
            ),
            const SizedBox(height: 8),
            // App Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Versi 1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Description
            const Text(
              'LapangKu adalah aplikasi penyedia layanan booking lapangan olahraga terpercaya. Kami menghubungkan pemilik lapangan dengan para pecinta olahraga untuk memudahkan proses penyewaan jadwal lapangan secara cepat, aman, dan efisien.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            // Feature List
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fitur Utama:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.search, 'Cari lapangan terdekat dan terbaik'),
            _buildFeatureItem(Icons.calendar_today, 'Cek ketersediaan jadwal secara real-time'),
            _buildFeatureItem(Icons.payment, 'Pembayaran aman dan mudah'),
            _buildFeatureItem(Icons.history, 'Pantau riwayat pemesanan Anda'),
            const SizedBox(height: 40),
            // Footer
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 20),
            Text(
              'Â© 2026 LapangKu App',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Dibuat dengan â¤ï¸ untuk olahraga Indonesia',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B6B3A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1B6B3A), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
