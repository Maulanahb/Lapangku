import 'package:flutter/material.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // In a real app, you might show a snackbar here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Tentang LapangKu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION
            _buildHeroSection(),

            const SizedBox(height: 24),

            // FITUR UTAMA SECTION
            _buildFiturUtamaSection(),

            const SizedBox(height: 16),

            // INFORMASI SECTION
            _buildInformasiSection(),

            const SizedBox(height: 16),

            // LEGAL SECTION
            _buildLegalSection(),

            const SizedBox(height: 32),

            // FOOTER
            _buildFooter(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stadium_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'LapangKu',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Booking Lapangan Jadi Lebih Mudah',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(204),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'LapangKu adalah aplikasi terbaik untuk menemukan dan memesan lapangan olahraga favorit Anda. Dirancang dengan antarmuka yang bersih dan pengalaman yang mulus.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(204),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Versi 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiturUtamaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fitur Utama',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
            children: [
              _buildFiturItem(Icons.search, 'Cari Lapangan'),
              _buildFiturItem(Icons.calendar_today, 'Booking Online'),
              _buildFiturItem(Icons.confirmation_number_outlined, 'E-Tiket Digital'),
              _buildFiturItem(Icons.shield_outlined, 'Pembayaran Aman'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiturItem(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textHeading,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInformasiSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Versi Aplikasi', '1.0.0 (Build 42)'),
          _buildDivider(),
          _buildInfoItem('Developer', 'LapangKu Tech'),
          _buildDivider(),
          _buildInfoItem(
            'Email Support',
            'bantuan@lapangku.id',
            isLink: true,
            onTap: () => _launchURL('mailto:bantuan@lapangku.id'),
          ),
          _buildDivider(),
          _buildInfoItem(
            'Website',
            'www.lapangku.id',
            isLink: true,
            onTap: () => _launchURL('https://www.lapangku.id'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isLink = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isLink ? AppColors.primary : AppColors.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          _buildMenuItem('Syarat & Ketentuan', () {}),
          _buildDivider(),
          _buildMenuItem('Kebijakan Privasi', () {}),
          _buildDivider(),
          _buildMenuItem('Lisensi Aplikasi', () {}),
          _buildDivider(),
          _buildMenuItem('Ikuti Kami', () => _launchURL('https://instagram.com/lapangku')),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textHeading,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
        size: 20,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.divider);
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          '© 2026 LapangKu Indonesia',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Made with ',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Icon(Icons.favorite, color: Colors.red, size: 14),
            Text(
              ' for sports enthusiasts',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
