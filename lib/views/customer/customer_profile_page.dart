import 'dart:io'; // NEW:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // NEW:
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/services/firebase_storage_service.dart'; // NEW:
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'personal_info_page.dart';
import 'security_page.dart';
import 'help_page.dart';
import 'about_page.dart';
import 'contact_cs_page.dart'; // FIX:
import 'notification_settings_page.dart'; // FIX:

class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  ConsumerState<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => _buildErrorView(context, error.toString()),
        data: (user) {
          if (user == null) {
            return EmptyStateWidget(
              icon: Icons.person_off_outlined,
              title: 'Data profil tidak ditemukan',
              subtitle: 'Silakan masuk kembali untuk melihat profil Anda.',
              actionButton: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Ke Halaman Login', style: TextStyle(color: Colors.white)),
              ),
            );
          }
          return _buildProfileContent(context, user);
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Gagal Memuat Profil',
      subtitle: error,
      actionButton: ElevatedButton.icon(
        onPressed: () => ref.invalidate(authStateProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('Coba Lagi'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HEADER SECTION
          _buildHeader(user),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION AKUN
                _buildSectionTitle('Akun'),
                _buildSectionCard([
                  _buildMenuItem(
                    icon: Icons.person_outlined,
                    title: 'Informasi Pribadi',
                    subtitle: 'Ubah data diri & profil',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoPage())),
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outlined,
                    title: 'Keamanan',
                    subtitle: 'Kata sandi & PIN',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage())),
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi',
                    subtitle: 'Atur pemberitahuan',
                    showDivider: false,
                    onTap: () => Navigator.push( // FIX:
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationSettingsPage()),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // SECTION BANTUAN
                _buildSectionTitle('Bantuan'),
                _buildSectionCard([
                  _buildMenuItem(
                    icon: Icons.help_outlined,
                    title: 'Bantuan & FAQ',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage())),
                  ),
                  _buildMenuItem(
                    icon: Icons.headset_mic_outlined,
                    title: 'Hubungi CS',
                    onTap: () => Navigator.push( // FIX:
                      context,
                      MaterialPageRoute(builder: (_) => const ContactCsPage()),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outlined,
                    title: 'Tentang LapangKu',
                    showDivider: false,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                  ),
                ]),

                const SizedBox(height: 40),

                // LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // VERSION TEXT
                const Center(
                  child: Text(
                    'Versi Aplikasi 1.0.4',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(
                        user.nama.trim().isNotEmpty
                            ? user.nama.trim().split(' ').where((l) => l.isNotEmpty).map((l) => l[0]).take(2).join().toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              // NEW: GestureDetector untuk mengubah foto profil
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context, user),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySelected.withAlpha(77),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(128)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Terverifikasi',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Fungsi untuk menampilkan pilihan sumber gambar (kamera/galeri)
  void _showImageSourceActionSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery, user);
              },
            ),
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Hapus Foto', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeletePhoto(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  // NEW: Fungsi untuk mengambil dan mengupload gambar
  Future<void> _pickAndUploadImage(ImageSource source, UserModel user) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Kompresi untuk menghemat kuota Cloudinary
      );

      if (image != null) {
        if (!mounted) return;
        LoadingOverlay.show(context, message: 'Mengunggah foto...');

        // 1. Upload ke Firebase Storage
        final String? imageUrl = await FirebaseStorageService.uploadImage(File(image.path), folder: 'avatars');

        if (imageUrl != null) {
          // 2. Update di Firebase via AuthNotifier
          await ref.read(authProvider.notifier).updateAvatar(user.uid, imageUrl);

          if (!mounted) return;
          LoadingOverlay.dismiss(context);
          
          // Force update UI
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui foto: $e')),
        );
      }
    }
  }

  // NEW: Fungsi untuk menghapus foto profil
  Future<void> _handleDeletePhoto(UserModel user) async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Hapus Foto',
      message: 'Apakah Anda yakin ingin menghapus foto profil?',
      confirmText: 'Hapus',
      isDestructive: true,
    );

    if (confirm == true) {
      if (!mounted) return;
      LoadingOverlay.show(context, message: 'Menghapus foto...');

      try {
        await ref.read(authProvider.notifier).updateAvatar(user.uid, null);
        
        if (!mounted) return;
        LoadingOverlay.dismiss(context);
        
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil telah dihapus')),
        );
      } catch (e) {
        if (mounted) {
          LoadingOverlay.dismiss(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus foto: $e')),
          );
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textHeading,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool showDivider = true,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textHeading,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                )
              : null,
          trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin keluar dari akun?',
      confirmText: 'Keluar',
      isDestructive: true,
    );

    if (confirm == true) {
      if (!mounted) return;
      LoadingOverlay.show(context, message: 'Mengeluarkan akun...');
      
      try {
        await ref.read(authProvider.notifier).logout();
        if (!mounted) return;
        LoadingOverlay.dismiss(context);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } catch (e) {
        if (!mounted) return;
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal logout: $e')),
        );
      }
    }
  }
}
