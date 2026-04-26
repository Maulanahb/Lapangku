import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  ConsumerState<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  // State untuk toggle Notifikasi
  bool _isNotificationOn = true;

  // Definisi warna yang digunakan
  final Color primaryGreen = const Color(0xFF1B5E20); // Hijau Tua
  final Color lightGreen = const Color(
    0xFF438A5E,
  ); // Hijau lebih terang untuk tombol Edit Profil

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: Colors.grey[200], // Background abu-abu muda
      body: SingleChildScrollView(
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
                        print('Tombol Edit Profil ditekan');
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
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(
                              0,
                              4,
                            ), // Bayangan ke bawah sedikit
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('12', 'Pesanan'),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[200],
                          ),
                          _buildStatItemWithStar('4.9', 'Rating'),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[200],
                          ),
                          _buildStatItem('3', 'Favorit'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Grup Akun
                    _buildSectionTitle('Akun'),
                    _buildMenuTile(
                      Icons.person_outline,
                      'Informasi Pribadi',
                      null,
                      true,
                    ),
                    _buildMenuTile(
                      Icons.payments_outlined,
                      'Metode Pembayaran',
                      'BCA, GoPay',
                      true,
                    ),
                    _buildNotificationTile(),
                    _buildMenuTile(
                      Icons.shield_outlined,
                      'Keamanan',
                      null,
                      false,
                    ),

                    const SizedBox(height: 24),

                    // Grup Aktivitas
                    _buildSectionTitle('Aktivitas'),
                    _buildMenuTile(
                      Icons.history,
                      'Riwayat Pesanan',
                      null,
                      true,
                    ),
                    _buildMenuTile(
                      Icons.favorite_border,
                      'Lapangan Favorit',
                      null,
                      true,
                    ),
                    _buildMenuTile(
                      Icons.rate_review_outlined,
                      'Ulasan Saya',
                      null,
                      false,
                    ),

                    const SizedBox(height: 24),

                    // Grup Lainnya
                    _buildSectionTitle('Lainnya'),
                    _buildMenuTile(
                      Icons.help_outline,
                      'Bantuan & FAQ',
                      null,
                      true,
                    ),
                    _buildMenuTile(
                      Icons.gavel_outlined,
                      'Syarat & Ketentuan',
                      null,
                      true,
                    ),
                    _buildMenuTile(
                      Icons.info_outline,
                      'Tentang LapangKu',
                      'v1.0.0',
                      false,
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
                          ref.read(authProvider.notifier).logout();
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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

  Widget _buildMenuTile(
    IconData icon,
    String title,
    String? subtitle,
    bool showDivider,
  ) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.blueGrey, size: 24),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )
              : null,
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 16,
          ),
          onTap: () {
            print('Membuka halaman: $title');
          },
        ),
        if (showDivider)
          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
      ],
    );
  }

  Widget _buildNotificationTile() {
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
            value: _isNotificationOn,
            activeColor: Colors.white,
            activeTrackColor: primaryGreen,
            onChanged: (value) {
              setState(() {
                _isNotificationOn = value;
              });
              print('Status Notifikasi diubah menjadi: $value');
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
