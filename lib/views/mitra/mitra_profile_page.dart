import 'dart:io'; // NEW: Import File
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // NEW: Import ImagePicker
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
// NEW: Import MitraController
import 'package:lapangku/models/mitra/mitra_profile_model.dart';
// NEW: Import FirebaseStorageService
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';

// Navigation Pages
import 'mitra_booking_list_page.dart';
import 'mitra_fields_page.dart';
import 'mitra_help_page.dart';
import 'mitra_profile_document_page.dart';
import 'mitra_revenue_page.dart';
import 'mitra_reviews_page.dart';
import 'mitra_schedule_page.dart';

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
        automaticallyImplyLeading: false,
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
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                ref.read(mitraProfileProvider.notifier).loadProfile(uid);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ),
        data: (profile) => SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(context, ref, profile), // NEW: Pass ref
              const SizedBox(height: 24),
              _buildMenuSection(
                title: "MANAJEMEN BISNIS",
                items: [
                  _buildMenuItem(
                    context,
                    icon: Icons.stadium_outlined,
                    title: "Lapangan Saya",
                    subtitle: "${profile.totalFields} lapangan aktif",
                    subtitleColor: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MitraFieldsPage()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: "Jadwal & Ketersediaan",
                    subtitle: "Atur slot booking",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MitraSchedulePage()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: "Pesanan Masuk",
                    subtitle: "${profile.totalOrders} perlu konfirmasi",
                    subtitleColor: Colors.orange,
                    badgeCount: profile.totalOrders,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MitraBookingListPage()),
                    ),
                  ),
                ],
              ),
              _buildMenuSection(
                title: "LAPORAN",
                items: [
                  _buildMenuItem(
                    context,
                    icon: Icons.trending_up,
                    title: "Pendapatan",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MitraRevenuePage()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.star,
                    title: "Ulasan Pelanggan",
                    subtitle: "${profile.rating} rata-rata",
                    subtitleColor: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MitraReviewsPage()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bar_chart,
                    title: "Statistik Booking",
                    onTap: () {}, // Kosong dulu
                  ),
                ],
              ),
              _buildMenuSection(
                title: "AKUN & PENGATURAN",
                items: [
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: "Informasi Pribadi",
                    subtitle: "Ubah data diri & profil",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MitraProfileDocumentPage()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock_outlined,
                    title: "Keamanan",
                    subtitle: "Kata sandi & PIN",
                    onTap: () {}, // Kosong dulu
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: "Notifikasi",
                    subtitle: "Atur pemberitahuan",
                    onTap: () {}, // Kosong dulu
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: "Tentang LapangKu",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MitraHelpPage()),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Versi Aplikasi 1.0.4',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, WidgetRef ref, MitraProfileModel profile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 32, top: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showImagePicker(context, ref, profile),
            child: Stack(
              children: [
                CircleAvatar(
                  key: ValueKey(profile.logoUrl),
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      profile.logoUrl != null && profile.logoUrl!.isNotEmpty
                          ? NetworkImage(profile.logoUrl!)
                          : null,
                  child: profile.logoUrl == null || profile.logoUrl!.isEmpty
                      ? Text(
                          _getInitials(profile.businessName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
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
          if (profile.isVerified) ...[
            const SizedBox(height: 8),
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
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
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

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          child: Column(children: items),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textHeading,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor ?? AppColors.textSecondary,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'MT';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
  }

  // NEW: BottomSheet pilihan sumber gambar
  void _showImagePicker(BuildContext context, WidgetRef ref, MitraProfileModel profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Ambil dari Kamera'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(context, ref, ImageSource.camera, profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Pilih dari Galeri'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(context, ref, ImageSource.gallery, profile);
            },
          ),
          if (profile.logoUrl != null && profile.logoUrl!.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(context, ref, profile);
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // NEW: Memilih gambar
  Future<void> _pickImage(BuildContext context, WidgetRef ref, ImageSource source, MitraProfileModel profile) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    if (!context.mounted) return;
    LoadingOverlay.show(context, message: 'Mengunggah foto...');

    try {
      final file = File(pickedFile.path);
      // NEW: Notifier.uploadLogo sudah menangani upload ke Cloudinary & simpan ke Firestore
      await ref.read(mitraProfileProvider.notifier).uploadLogo(file);

      if (context.mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui foto: $e')),
        );
      }
    }
  }

  // NEW: Menghapus foto
  Future<void> _deletePhoto(BuildContext context, WidgetRef ref, MitraProfileModel profile) async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Hapus Foto?',
      message: 'Apakah Anda yakin ingin menghapus foto profil?',
      confirmText: 'Hapus',
      isDestructive: true,
    );

    if (confirm == true) {
      if (!context.mounted) return;
      LoadingOverlay.show(context, message: 'Menghapus foto...');
      try {
        await ref.read(mitraProfileProvider.notifier).deleteLogo();


        if (context.mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto telah dihapus')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus foto: $e')),
          );
        }
      }
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Keluar dari Akun',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi Lapangku?',
      confirmText: 'Keluar',
      isDestructive: true,
    );

    if (confirm == true) {
      if (!context.mounted) return;
      LoadingOverlay.show(context, message: 'Keluar...');
      try {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          LoadingOverlay.dismiss(context);
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal keluar: $e')),
          );
        }
      }
    }
  }
}
