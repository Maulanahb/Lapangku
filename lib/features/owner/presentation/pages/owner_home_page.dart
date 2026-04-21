// lib/features/owner/presentation/pages/owner_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/owner_field_provider.dart';
// TODO: Jangan lupa import model FieldEntity kamu dan booking model (jika ada) nanti
// import '../../domain/entities/field_entity.dart';
// import '../../../booking/domain/entities/booking_entity.dart';

class OwnerHomePage extends ConsumerStatefulWidget {
  const OwnerHomePage({super.key});

  @override
  ConsumerState<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends ConsumerState<OwnerHomePage> {
  // Variabel statis untuk tampilan, ganti dengan state management Riverpod nanti
  final int _bookingTodayCount = 8;
  final String _revenueToday = 'Rp 960K';
  final int _activeFields = 3;
  final int _totalFields = 3;
  final double _rating = 4.8;
  final int _reviewCount = 67;
  final String _revenue7Days = 'Rp 3.2 juta';
  final int _pendingConfirmations = 2;

  // Variabel untuk mengelola indeks navigasi bawah
  int _selectedIndex = 0;

  // Warna utama dari brief
  final Color _primaryColor = const Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB), // Latar belakang keabu-abuan
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.black),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '2', // Ganti dengan jumlah notifikasi sebenarnya nanti
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
            onPressed: () {
              // TODO: Tambahkan navigasi ke halaman notifikasi
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CircleAvatar(
              backgroundColor: _primaryColor,
              child: const Text(
                'BS',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Senin, 30 Maret 2024',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Bagian Statistik Utama
              _buildStatsGrid(),
              const SizedBox(height: 20),

              // Bagian Grafik Pendapatan
              _buildRevenueSection(),
              const SizedBox(height: 20),

              // Bagian Daftar Pesanan Menunggu Konfirmasi
              _buildBookingSectionHeader(),
              const SizedBox(height: 12),
              _buildPendingBookingCard(),
              const SizedBox(height: 20),

              // Bagian Promo / Peningkatan Performa
              _buildPromoCard(),
            ],
          ),
        ),
      ),
      // Navigasi bawah, ini static untuk tampilan, tambahkan state management nanti
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // TODO: Gunakan state management untuk mengubah indeks dan menavigasi
          // Untuk saat ini, kita hanya memperbarui tampilan di halaman ini
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Lapangan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    // 1. Ambil UID user yang sedang login (kasih nilai default kalau belum login saat ngetes)
    final String ownerId =
        FirebaseAuth.instance.currentUser?.uid ?? 'dummy_owner_id';

    // 2. Pantau provider lapangan berdasarkan ownerId
    final fieldsAsyncValue = ref.watch(ownerFieldsProvider(ownerId));

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          label: 'PESANAN HARI INI',
          value:
              '$_bookingTodayCount', // Ini nanti diganti pakai provider booking
          trendIcon: Icons.trending_up,
          trendText: '+2 dari kemarin',
          trendColor: Colors.green,
        ),
        _buildStatCard(
          label: 'PENDAPATAN HARI INI',
          value: _revenueToday, // Ini nanti diganti pakai provider pendapatan
          trendIcon: Icons.trending_up,
          trendText: '+15%',
          trendColor: Colors.green,
        ),

        // 3. Gunakan fieldsAsyncValue.when untuk kotak LAPANGAN AKTIF
        fieldsAsyncValue.when(
          data: (fields) {
            // Jika sukses, hitung jumlah lapangan milik owner ini
            final activeCount = fields.length;
            return _buildStatCard(
              label: 'LAPANGAN AKTIF',
              value: '$activeCount',
              trendText: 'dari total lapangan',
            );
          },
          loading: () => _buildStatCard(
            label: 'LAPANGAN AKTIF',
            value: '...', // Tampilkan titik-titik saat loading
            trendText: 'Memuat data...',
          ),
          error: (error, stack) => _buildStatCard(
            label: 'LAPANGAN AKTIF',
            value: '-',
            trendText: 'Gagal memuat',
          ),
        ),

        _buildStatCard(
          label: 'RATING',
          value: '$_rating', // Nanti diganti pakai data ulasan asli
          icon: Icons.star_rounded,
          iconColor: Colors.amber[700],
          trendText: '($_reviewCount ulasan)',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    String? trendText,
    IconData? trendIcon,
    Color? trendColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Row(
              children: [
                if (icon != null) Icon(icon, color: iconColor, size: 24),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
            if (trendText != null)
              Row(
                children: [
                  if (trendIcon != null)
                    Icon(trendIcon, color: trendColor, size: 16),
                  if (trendIcon != null) const SizedBox(width: 4),
                  Text(
                    trendText,
                    style: TextStyle(
                      color: trendColor ?? Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSection() {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendapatan 7 Hari',
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      _revenue7Days,
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Tambahkan aksi filter
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            // Placeholder untuk Grafik Pendapatan
            Container(
              height: 120,
              width: double.infinity,
              color: const Color(0xFFF6F8FB),
              child: const Center(
                child: Text(
                  'Grafik Pendapatan',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildChartLabels(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildChartLabel('SEN'),
        _buildChartLabel('SEL'),
        _buildChartLabel('RAB'),
        _buildChartLabel('KAM'),
        _buildChartLabel('JUM'),
        _buildChartLabel('SAB', isActive: true),
        _buildChartLabel('MIN'),
      ],
    );
  }

  Widget _buildChartLabel(String text, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: isActive
          ? BoxDecoration(
              color:
                  const Color(0xFFC7E6C1), // Hijau muda, sesuaikan jika perlu
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? _primaryColor : Colors.grey[700],
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBookingSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tambahkan Expanded di sini agar Row kiri menyesuaikan sisa ruang
        Expanded(
          child: Row(
            children: [
              // Tambahkan Expanded juga di Text-nya
              Expanded(
                child: Text(
                  'Pesanan Menunggu Konfirmasi',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Sedikit dikecilkan dari 18 biar lebih pas
                  ),
                  // Jika teks kepanjangan, akan dipotong pakai titik-titik (...)
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEDBB1), // Oranye muda
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_pendingConfirmations',
                  style: const TextStyle(
                    color: Color(0xFFE65100), // Oranye tua
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8), // Kasih jarak sedikit ke tombol
        TextButton.icon(
          onPressed: () {
            // TODO: Tambahkan navigasi ke semua pesanan
          },
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Lihat Semua'),
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
            padding:
                EdgeInsets.zero, // Hilangkan padding bawaan biar hemat tempat
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        )
      ],
    );
  }

  Widget _buildPendingBookingCard() {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Placeholder foto profil
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budi Santoso',
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '0812-3456-7890',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '5 menit lalu',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildBookingDetailRow(Icons.sports_soccer_outlined, 'Futsal A'),
            const SizedBox(height: 8),
            _buildBookingDetailRow(
                Icons.calendar_month_outlined, 'Sabtu 30 Mar'),
            const SizedBox(height: 8),
            _buildBookingDetailRow(Icons.access_time, '19:00-20:00'),
            const SizedBox(height: 8),
            _buildBookingDetailRow(
                Icons.account_balance_wallet_outlined, 'Transfer BCA'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rp 125.000',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Tambahkan aksi lihat bukti transfer
                  },
                  child: Text(
                    'Lihat Bukti',
                    style: TextStyle(
                        color: Colors.grey[700],
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Tambahkan aksi konfirmasi
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Konfirmasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Tambahkan aksi tolak
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Colors.grey[800], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPromoCard() {
    return Material(
      color: _primaryColor,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tingkatkan Performa Lapangan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan fitur promosi untuk menarik lebih banyak penyewa di jam-jam sepi.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Tambahkan navigasi ke halaman promosi
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC7E6C1), // Hijau muda
                foregroundColor: _primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Pelajari Fitur',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
