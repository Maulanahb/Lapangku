import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
import 'package:lapangku/utils/snackbar_helper.dart';

// Import newly created pages
import 'widgets/mitra_menu_tile.dart';
import 'mitra_profile_document_page.dart';
import 'mitra_fields_page.dart';
import 'mitra_schedule_page.dart';
import 'mitra_payout_page.dart';
import 'mitra_revenue_page.dart';
import 'mitra_reviews_page.dart';
import 'mitra_help_page.dart';
import 'mitra_language_page.dart';

class MitraProfilePage extends ConsumerWidget {
  const MitraProfilePage({super.key});

  final Color _primaryGreen = const Color(0xFF1B6B3A);
  final Color _lightGreen = const Color(0xFFD1FAE5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(mitraProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Gagal memuat profil', style: TextStyle(color: Colors.grey.shade700)),
              TextButton(
                onPressed: () => ref.read(mitraProfileProvider.notifier).loadProfile('mock_uid_123'),
                child: const Text('Coba Lagi', style: TextStyle(color: Color(0xFF1B6B3A))),
              )
            ],
          ),
        ),
        data: (profileState) => SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context, profileState),
              _buildStatsBar(profileState),
              const SizedBox(height: 8),
              _buildSectionTitle('BISNIS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    MitraMenuTile(
                      icon: Icons.description_outlined,
                      title: 'Profil & Dokumen',
                      subtitle: 'KTP, NPWP, dll',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraProfileDocumentPage())),
                    ),
                    MitraMenuTile(
                      icon: Icons.stadium_outlined,
                      title: 'Lapangan Saya',
                      subtitle: '${profileState.totalFields} lapangan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraFieldsPage())),
                    ),
                    MitraMenuTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Jadwal & Ketersediaan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraSchedulePage())),
                    ),
                    MitraMenuTile(
                      icon: Icons.account_balance_outlined,
                      title: 'Rekening Payout',
                      subtitle: profileState.bankName.isNotEmpty
                          ? '${profileState.bankName} Â· ${profileState.bankAccount}'
                          : 'Belum diatur',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraPayoutPage())),
                    ),
                  ],
                ),
              ),
              _buildSectionTitle('LAPORAN'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    MitraMenuTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Laporan Pendapatan',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraRevenuePage())),
                    ),
                    MitraMenuTile(
                      icon: Icons.star_outline_rounded,
                      title: 'Ulasan Pelanggan',
                      subtitle: '${profileState.rating} â­ rata-rata',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraReviewsPage())),
                    ),
                  ],
                ),
              ),
              _buildSectionTitle('PENGATURAN'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    MitraMenuTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifikasi Pesanan',
                      trailing: Switch(
                        value: profileState.notificationOrder,
                        onChanged: (v) => _toggleOrderNotif(context, ref, profileState),
                        activeThumbColor: Colors.white,
                        activeTrackColor: _primaryGreen,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                      ),
                      onTap: () => _toggleOrderNotif(context, ref, profileState),
                    ),
                    MitraMenuTile(
                      icon: Icons.campaign_outlined,
                      title: 'Notifikasi Promo',
                      trailing: Switch(
                        value: profileState.notificationPromo,
                        onChanged: (v) => _togglePromoNotif(context, ref, profileState),
                        activeThumbColor: Colors.white,
                        activeTrackColor: _primaryGreen,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                      ),
                      onTap: () => _togglePromoNotif(context, ref, profileState),
                    ),
                    MitraMenuTile(
                      icon: Icons.language_rounded,
                      title: 'Bahasa',
                      trailing: Text('Indonesia', style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraLanguagePage())),
                    ),
                    MitraMenuTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Bantuan & FAQ',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraHelpPage())),
                    ),
                    const SizedBox(height: 12),
                    _buildLogoutButton(context, ref),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleOrderNotif(BuildContext context, WidgetRef ref, MitraProfileModel state) async {
    try {
      await ref.read(mitraProfileProvider.notifier).toggleNotificationOrder();
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'Notifikasi pesanan ${!state.notificationOrder ? "diaktifkan" : "dimatikan"}');
      }
    } catch (e) {
      if (context.mounted) SnackbarHelper.showError(context, 'Gagal mengubah notifikasi');
    }
  }

  void _togglePromoNotif(BuildContext context, WidgetRef ref, MitraProfileModel state) async {
    try {
      await ref.read(mitraProfileProvider.notifier).toggleNotificationPromo();
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'Notifikasi promo ${!state.notificationPromo ? "diaktifkan" : "dimatikan"}');
      }
    } catch (e) {
      if (context.mounted) SnackbarHelper.showError(context, 'Gagal mengubah notifikasi');
    }
  }

  Widget _buildProfileHeader(BuildContext context, MitraProfileModel state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 40),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Text(
                    state.businessName.isNotEmpty ? state.businessName[0].toUpperCase() : 'G',
                    style: TextStyle(color: _primaryGreen, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.businessName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  if (state.isVerified) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: _primaryGreen, size: 12),
                          const SizedBox(width: 3),
                          Text('Terverifikasi', style: TextStyle(color: _primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                state.MitraName,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MitraProfileDocumentPage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('Edit Profil Bisnis', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(MitraProfileModel state) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            _buildStatItem('${state.totalFields}', 'Lapangan'),
            _buildStatDivider(),
            _buildStatItem('${state.totalOrders}', 'Pesanan'),
            _buildStatDivider(),
            _buildStatItemWithStar('${state.rating}', 'Rating'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatItemWithStar(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(width: 3),
              const Icon(Icons.star, color: Color(0xFFFFB800), size: 16),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 36, color: Colors.grey[200]);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.8),
        ),
      ),
    );
  }

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
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFFEE8E7), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFE04443), size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Keluar dari Akun',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFE04443)),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await ref.read(authProvider.notifier).logout();
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Keluar', style: TextStyle(color: Color(0xFFE04443), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
