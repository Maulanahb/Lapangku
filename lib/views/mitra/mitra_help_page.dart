import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

class MitraHelpPage extends StatelessWidget {
  const MitraHelpPage({super.key});

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri url = Uri.parse('https://wa.me/6281234567890?text=Halo%20Admin%20LapangKu,%20saya%20Mitra%20Pemilik%20Lapangan,%20butuh%20bantuan');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Tidak dapat membuka WhatsApp');
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri url = Uri.parse('mailto:support@lapangku.com?subject=Bantuan%20Mitra%20LapangKu');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Tidak dapat membuka Email');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Bantuan & FAQ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hubungi Kami', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.chat,
              title: 'WhatsApp Admin',
              subtitle: 'Respon cepat (08:00 - 22:00)',
              onTap: () => _launchWhatsApp(context),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@lapangku.com',
              onTap: () => _launchEmail(context),
            ),
            const SizedBox(height: 24),
            const Text('Frequently Asked Questions (FAQ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildFaqTile('Bagaimana cara menambahkan lapangan baru?', 'Anda dapat menambahkan lapangan melalui menu "Lapangan Saya" lalu klik tombol "Tambah" di sudut kanan bawah.'),
                  _buildDivider(),
                  _buildFaqTile('Kapan dana akan dicairkan ke rekening saya?', 'Dana pencairan (payout) diproses setiap hari Senin untuk akumulasi pendapatan minggu sebelumnya.'),
                  _buildDivider(),
                  _buildFaqTile('Bagaimana cara membatalkan pesanan masuk?', 'Pesanan yang sudah dibayar tidak dapat dibatalkan secara sepihak. Silakan hubungi admin LapangKu jika terjadi kendala operasional.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: const Color(0xFF1B6B3A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF1B6B3A)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: const Color(0xFF1B6B3A),
        collapsedIconColor: Colors.grey,
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );
  }
}
