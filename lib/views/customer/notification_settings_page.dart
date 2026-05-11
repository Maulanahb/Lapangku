import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  
  Future<void> _toggleSetting(String field, bool value, UserModel user) async {
    // 1. Siapkan data pengaturan baru
    final currentSettings = Map<String, bool>.from(user.notificationSettings);
    final newSettings = Map<String, bool>.from(currentSettings);
    newSettings[field] = value;

    // 2. Tampilkan loading overlay
    LoadingOverlay.show(context, message: 'Menyimpan perubahan...');

    try {
      // 3. Panggil method update di AuthNotifier (menangani Firestore)
      await ref.read(authProvider.notifier).updateNotificationSettings(
            user.uid,
            newSettings,
          );
      
      if (!mounted) return;
      LoadingOverlay.dismiss(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan notifikasi berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      LoadingOverlay.dismiss(context);
      
      // Tampilkan error jika gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui pengaturan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      // State Switch akan kembali otomatis karena provider mengalirkan data lama kembali
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Gagal Memuat Pengaturan',
          subtitle: err.toString(),
          actionButton: ElevatedButton(
            onPressed: () => ref.invalidate(authStateProvider),
            child: const Text('Coba Lagi'),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const EmptyStateWidget(
              icon: Icons.person_off_outlined,
              title: 'Data tidak ditemukan',
              subtitle: 'Silakan login kembali.',
            );
          }
          return _buildContent(user);
        },
      ),
    );
  }

  Widget _buildContent(UserModel user) {
    final settings = user.notificationSettings;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('PESANAN'),
          _buildSettingsCard([
            _buildSwitchItem(
              icon: Icons.receipt_long_outlined,
              title: 'Status Booking',
              subtitle: 'Update konfirmasi dan jadwal',
              value: settings['notificationOrder'] ?? true,
              onChanged: (val) => _toggleSetting('notificationOrder', val, user),
            ),
            _buildSwitchItem(
              icon: Icons.alarm_outlined,
              title: 'Pengingat Bermain',
              subtitle: 'H-1 dan 2 jam sebelum main',
              value: settings['notificationReminder'] ?? true,
              onChanged: (val) => _toggleSetting('notificationReminder', val, user),
            ),
            _buildSwitchItem(
              icon: Icons.payment_outlined,
              title: 'Pembayaran',
              subtitle: 'Tagihan dan status lunas',
              value: settings['notificationPayment'] ?? true,
              onChanged: (val) => _toggleSetting('notificationPayment', val, user),
              showDivider: false,
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionTitle('INFORMASI'),
          _buildSettingsCard([
            _buildSwitchItem(
              icon: Icons.discount_outlined,
              title: 'Promo & Diskon',
              subtitle: 'Penawaran lapang terbaru',
              value: settings['notificationPromo'] ?? true,
              onChanged: (val) => _toggleSetting('notificationPromo', val, user),
            ),
            _buildSwitchItem(
              icon: Icons.system_update_outlined,
              title: 'Info Sistem',
              subtitle: 'Update fitur dan maintenance',
              value: settings['notificationSystem'] ?? true,
              onChanged: (val) => _toggleSetting('notificationSystem', val, user),
              showDivider: false,
            ),
          ]),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
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
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kelola Notifikasi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Atur notifikasi yang ingin kamu terima dari LapangKu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
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
                        fontSize: 15,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
      ],
    );
  }
}
