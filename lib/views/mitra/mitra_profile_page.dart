import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';

// Import target halaman navigasi
import 'mitra_fields_page.dart';
import 'mitra_schedule_page.dart';
import 'mitra_booking_list_page.dart';
import 'mitra_revenue_page.dart';
import 'mitra_reviews_page.dart';
import 'mitra_profile_document_page.dart';
import 'mitra_help_page.dart';

class MitraProfilePage extends ConsumerWidget {
  const MitraProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(mitraProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        // FIX: Hapus AppBar leading (icon menu)
        // FIX: Hapus AppBar actions (icon lonceng)
        title: const Text(
          'Profil Mitra',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Gagal memuat profil',
          subtitle: err.toString(),
          actionButton: ElevatedButton(
            onPressed: () => ref.refresh(mitraProfileProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ),
        data: (profile) => SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(profile),
              const SizedBox(height: 24),
              _buildSectionTitle('MANAJEMEN BISNIS'), // FIX: Teks langsung tanpa container khusus
              _buildBusinessManagementCard(context, profile),
              const SizedBox(height: 24),
              _buildSectionTitle('LAPORAN'), // FIX: Teks langsung
              _buildReportCard(context, profile),
              const SizedBox(height: 24),
              _buildSectionTitle('AKUN & PENGATURAN'), // FIX: Teks langsung
              _buildSettingsCard(context),
              const SizedBox(height: 32),
              _buildLogoutSection(context, ref),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(MitraProfileModel profile) {
    final String businessName = profile.businessName.toUpperCase();
    String initial = 'M';
    if (businessName.isNotEmpty) {
      final parts = businessName.split(' ');
      if (parts.length >= 2) {
        initial = parts[0][0] + parts[1][0];
      } else {
        initial = businessName.length >= 3 ? businessName.substring(0, 3) : businessName;
      }
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Stack( // FIX: Tetapkan icon camera di hero section
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.businessName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (profile.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Mitra Terverifikasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            profile.MitraName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessManagementCard(BuildContext context, MitraProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.stadium_outlined,
            title: 'Lapangan Saya',
            subtitle: '${profile.totalFields} lapangan aktif',
            subtitleColor: Colors.green, // FIX: Colors.green
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraFieldsPage())),
          ),
          // FIX: Hapus Divider
          _buildMenuItem(
            icon: Icons.calendar_month_outlined,
            title: 'Jadwal & Ketersediaan',
            subtitle: 'Atur slot booking',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraSchedulePage())),
          ),
          // FIX: Hapus Divider
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'Pesanan Masuk',
            subtitle: '${profile.totalOrders} perlu konfirmasi',
            subtitleColor: Colors.orange, // FIX: Colors.orange
            badge: profile.totalOrders > 0 ? '${profile.totalOrders}' : null, // FIX: Tetapkan badge merah
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraBookingListPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, MitraProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.trending_up,
            title: 'Pendapatan',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraRevenuePage())),
          ),
          // FIX: Hapus Divider
          _buildMenuItem(
            icon: Icons.star,
            title: 'Ulasan Pelanggan',
            subtitle: '${profile.rating} rata-rata',
            subtitleColor: Colors.orange, // FIX: Colors.orange
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraReviewsPage())),
          ),
          // FIX: Hapus Divider
          _buildMenuItem(
            icon: Icons.bar_chart,
            title: 'Statistik Booking',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Informasi Pribadi',
            subtitle: 'Ubah data diri & profil',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraProfileDocumentPage())),
          ),
          // FIX: Hapus Divider
          _buildMenuItem(
            icon: Icons.lock_outlined,
            title: 'Keamanan',
            subtitle: 'Kata sandi & PIN',
            onTap: () {},
          ),
          // FIX: Hapus Divider
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            subtitle: 'Atur pemberitahuan',
            onTap: () {},
          ),
          // FIX: Hapus Divider
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Tentang LapangKu',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraHelpPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textHeading, // FIX: AppColors.textHeading
          ),
        ),
      ),
    );
  }

<<<<<<< Updated upstream

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showLogoutDialog(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFFFEE8E7),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFE04443), size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Keluar dari Akun',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE04443)),
=======
  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context, ref),
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
>>>>>>> Stashed changes
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Versi Aplikasi 1.0.4', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight, // FIX: Semua background icon SAMA
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24), // FIX: Semua icon color SAMA
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: subtitleColor ?? AppColors.textSecondary),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20), // FIX: Tetapkan Chevron
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Keluar',
      message: 'Apakah Anda yakin ingin keluar dari akun?',
      confirmText: 'Keluar',
      isDestructive: true,
    );

    if (confirm) {
      LoadingOverlay.show(context, message: 'Mengeluarkan...');
      try {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          LoadingOverlay.dismiss(context);
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal keluar: $e')));
        }
      }
    }
  }
}
