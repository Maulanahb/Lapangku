import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri url = Uri.parse('https://wa.me/6281234567890?text=Halo%20Admin%20LapangKu,%20saya%20butuh%20bantuan');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Tidak dapat membuka WhatsApp');
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri url = Uri.parse('mailto:support@lapangku.com?subject=Bantuan%20LapangKu');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Tidak dapat membuka Email');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bantuan & FAQ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hubungi Kami',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.chat_bubble_outline,
              title: 'WhatsApp Admin',
              subtitle: 'Respon cepat (08:00 - 20:00)',
              color: Colors.green,
              onTap: () => _launchWhatsApp(context),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@lapangku.com',
              color: Colors.blue,
              onTap: () => _launchEmail(context),
            ),
            const SizedBox(height: 32),
            const Text(
              'FAQ (Pertanyaan Umum)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'Bagaimana cara memesan lapangan?',
              'Anda dapat mencari lapangan melalui halaman Beranda atau Pencarian, pilih jadwal yang tersedia, dan ikuti instruksi pembayaran untuk menyelesaikan pesanan.',
            ),
            _buildFaqItem(
              'Metode pembayaran apa saja yang didukung?',
              'Saat ini kami mendukung pembayaran melalui transfer bank (BCA, Mandiri, BNI) dan E-Wallet (GoPay, OVO, Dana).',
            ),
            _buildFaqItem(
              'Apakah saya bisa membatalkan pesanan?',
              'Pesanan dapat dibatalkan maksimal 24 jam sebelum jadwal main. Dana akan dikembalikan ke saldo LapangKu Anda.',
            ),
            _buildFaqItem(
              'Bagaimana jika lapangan tutup saat jadwal saya?',
              'Silakan hubungi admin melalui WhatsApp beserta bukti pesanan Anda. Kami akan memproses pengembalian dana 100%.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        expandedAlignment: Alignment.centerLeft,
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
