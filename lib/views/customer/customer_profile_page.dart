import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'personal_info_page.dart';
import 'payment_method_page.dart';
import 'security_page.dart';
import 'favorites_page.dart';
import 'reviews_page.dart';
import 'help_page.dart';
import 'terms_page.dart';
import 'about_page.dart';
import 'customer_orders_page.dart';

import 'package:lapangku/controllers/profile/profile_provider.dart';
import 'package:lapangku/controllers/favorite/favorite_controller.dart';
import 'widgets/profile_menu_tile.dart';

class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  ConsumerState<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  // Definisi warna yang digunakan
  final Color primaryGreen = const Color(0xFF1B5E20); // Hijau Tua
  final Color lightGreen = const Color(
    0xFF438A5E,
  ); // Hijau lebih terang untuk tombol Edit Profil

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final profileState = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200], // Background abu-abu muda
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorView(context, error.toString()),
        data: (user) => _buildProfileContent(context, user, profileState),
      ),
    );
  }

  /// Tampilan error dengan tombol coba lagi
  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Koneksi ke server gagal. Pastikan internet kamu stabil lalu coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Refresh/invalidate provider untuk retry
                ref.invalidate(authStateProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  /// Konten profil utama (dipindah dari build agar rapi)
  Widget _buildProfileContent(BuildContext context, UserModel? user, ProfileState profileState) {
    return SingleChildScrollView(
        child: Stack(
          children: [
            // 1. Header Bagian Atas (Lengkungan Hijau)
            ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                width: double.infinity,
                height: 290,
                color: primaryGreen,
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                          ? Text(
                              user?.nama.isNotEmpty == true ? user!.nama[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Color(0xFF1B5E20),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Nama
                    Text(
                      user?.nama ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      user?.email ?? 'email@domain.com',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    // Tombol Edit Profil
                    InkWell(
                      onTap: () {
                        // TODO: Navigate to Edit Profile Page
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Edit Profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Konten Utama (Card Putih Murni di atas background abu-abu)
            Container(
              margin: const EdgeInsets.only(
                top: 250,
              ), // Overlap dengan header hijau sebesar 40px
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Statistik (Pesanan, Rating, Favorit)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(
                              0,
                              4,
                            ), // Bayangan ke bawah sedikit
                          ),
                        ],
                      ),
                      child: profileState.isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(profileState.totalOrders.toString(), 'Pesanan'),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey[200],
                                ),
                                _buildStatItemWithStar(profileState.rating.toString(), 'Rating'),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey[200],
                                ),
                                _buildStatItem(
                                  ref.watch(favoritesCountProvider).when(
                                    data: (count) => count.toString(),
                                    loading: () => '...',
                                    error: (_, __) => '0',
                                  ),
                                  'Favorit',
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 30),

                    // Grup Akun
                    _buildSectionTitle('Akun'),
                    ProfileMenuTile(
                      icon: Icons.person_outline,
                      title: 'Informasi Pribadi',
                      showDivider: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoPage())),
                    ),
                    ProfileMenuTile(
                      icon: Icons.payments_outlined,
                      title: 'Metode Pembayaran',
                      subtitle: 'BCA, GoPay',
                      showDivider: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodPage())),
                    ),
                    _buildNotificationTile(context, profileState),
                    ProfileMenuTile(
                      icon: Icons.shield_outlined,
                      title: 'Keamanan',
                      showDivider: false,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage())),
                    ),

                    const SizedBox(height: 24),

                    // Grup Aktivitas
                    _buildSectionTitle('Aktivitas'),
                    ProfileMenuTile(
                      icon: Icons.history,
                      title: 'Riwayat Pesanan',
                      showDivider: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrdersPage())),
                    ),
                    ProfileMenuTile(
                      icon: Icons.favorite_border,
                      title: 'Lapangan Favorit',
                      showDivider: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
                    ),
                    ProfileMenuTile(
                      icon: Icons.rate_review_outlined,
                      title: 'Ulasan Saya',
                      showDivider: false,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage())),
                    ),

                    const SizedBox(height: 24),

                    // Grup Lainnya
                    _buildSectionTitle('Lainnya'),
                    ProfileMenuTile(
                      icon: Icons.help_outline,
                      title: 'Bantuan & FAQ',
                      showDivider: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage())),
                    ),
                    ProfileMenuTile(
                      icon: Icons.gavel_outlined,
                      title: 'Syarat & Ketentuan',
                      showDivider: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage())),
                    ),
                    ProfileMenuTile(
                      icon: Icons.info_outline,
                      title: 'Tentang LapangKu',
                      subtitle: 'v1.0.0',
                      showDivider: false,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                    ),

                    const SizedBox(height: 40),

                    // Tombol Keluar / Logout
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Logout'),
                              content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    ref.read(authProvider.notifier).logout();
                                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                  },
                                  child: const Text('Keluar', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Keluar',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Padding ekstra di bawah
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  // --- Fungsi Bantuan Pembuatan Komponen ---

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: primaryGreen,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItemWithStar(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.star, color: Colors.orange, size: 18),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: primaryGreen,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _buildNotificationTile(BuildContext context, ProfileState state) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.notifications_none,
            color: Colors.blueGrey,
            size: 24,
          ),
          title: const Text(
            'Notifikasi',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: Switch(
            value: state.isNotificationOn,
            activeThumbColor: Colors.white,
            activeTrackColor: primaryGreen,
            onChanged: (value) {
              ref.read(profileStateProvider.notifier).toggleNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Notifikasi diaktifkan' : 'Notifikasi dinonaktifkan',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
      ],
    );
  }

}
// --- Custom Clipper untuk Lengkungan Header ---
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    // Membuat lengkungan kurva dari ujung kiri ke kanan ujung bawah
    path.quadraticBezierTo(
      size.width / 2,
      size.height, // Control point
      size.width,
      size.height - 40, // End point
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
