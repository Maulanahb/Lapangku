// lib/views/Mitra/mitra_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapangku/controllers/mitra/mitra_controller.dart';

class MitraHomePage extends ConsumerStatefulWidget {
  const MitraHomePage({super.key});

  @override
  ConsumerState<MitraHomePage> createState() => _MitraHomePageState();
}

class _MitraHomePageState extends ConsumerState<MitraHomePage> {
  final Color _primaryGreen = const Color(0xFF0F5A3C);
  final Color _bgLightGreen = const Color(0xFFE8F5EF);
  final Color _bgLightRed = const Color(0xFFFEE8E7);
  final Color _textRed = const Color(0xFFE04443);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildStatsGrid(),
                      const SizedBox(height: 32),
                      _buildWaitingListHeader(),
                      const SizedBox(height: 16),
                      _buildWaitingOrderCard(),
                      const SizedBox(height: 32),
                      _buildRevenueSummarySection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const CircleAvatar(
                radius: 20,
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?img=12')),
            const SizedBox(width: 12),
            Text('LapangKu',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _primaryGreen)),
          ]),
          Stack(children: [
            const Icon(Icons.notifications_outlined,
                size: 28, color: Colors.black87),
            Positioned(
                right: 0,
                top: 0,
                child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE04443), shape: BoxShape.circle),
                    child: const Text('2',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)))),
          ]),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    // Mengambil waktu saat ini
    final now = DateTime.now();

    // Array untuk nama hari dan bulan dalam bahasa Indonesia
    final List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    // Membentuk string tanggal yang rapi
    final String currentDate =
        '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Dashboard',
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black)),
      const SizedBox(height: 4),
      Text(currentDate, // <--- Tanggal sekarang otomatis tampil di sini
          style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildStatsGrid() {
    final String mitraId =
        FirebaseAuth.instance.currentUser?.uid ?? 'dummy_mitra_id';
    final fieldsAsyncValue = ref.watch(mitraFieldsProvider(mitraId));

    return Column(children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: _buildStatCard(
                  label: 'Pesanan Hari Ini',
                  value: '8',
                  trend: 'â†‘2',
                  trendColor: Colors.green,
                  footer: 'dari kemarin')),
          const SizedBox(width: 12),
          Expanded(
              child: _buildStatCard(
                  label: 'Pendapatan Hari Ini',
                  value: 'Rp 960K',
                  valueColor: _primaryGreen,
                  trend: 'â†‘15%',
                  trendColor: Colors.green,
                  footer: '')),
        ]),
      ),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: fieldsAsyncValue.when(
              data: (fields) => _buildStatCard(
                  label: 'Lapangan Aktif',
                  value: '${fields.length}',
                  footer: 'dari total lapangan'),
              loading: () => _buildStatCard(
                  label: 'Lapangan Aktif',
                  value: '...',
                  footer: 'Memuat data...'),
              error: (error, stack) => _buildStatCard(
                  label: 'Lapangan Aktif', value: '-', footer: 'Gagal memuat'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: _buildStatCard(
                  label: 'Rating Rata-rata',
                  value: '4.8',
                  hasStar: true,
                  footer: '(67 ulasan)')),
        ]),
      ),
    ]);
  }

  Widget _buildStatCard(
      {required String label,
      required String value,
      String? trend,
      Color? trendColor,
      required String footer,
      Color? valueColor,
      bool hasStar = false}) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return GestureDetector(
          onTapDown: (_) => setLocalState(() => isPressed = true),
          onTapUp: (_) => setLocalState(() => isPressed = false),
          onTapCancel: () => setLocalState(() => isPressed = false),
          onLongPress: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPressed ? const Color(0xFFF6FBF8) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPressed
                    ? _primaryGreen.withOpacity(0.3)
                    : Colors.grey[100]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                    color: isPressed
                        ? _primaryGreen.withOpacity(0.18)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: isPressed ? 18 : 10,
                    spreadRadius: isPressed ? 2 : 0,
                    offset: const Offset(0, 4))
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700])),
              const SizedBox(height: 12),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: valueColor ?? Colors.black)),
                    if (hasStar) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 18)
                    ],
                    if (trend != null) ...[
                      const Spacer(),
                      Text(trend,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: trendColor))
                    ],
                  ]),
              if (footer.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(footer,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500))
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _buildWaitingListHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        const Text('Pesanan Menunggu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFFFEE8E7),
                borderRadius: BorderRadius.circular(12)),
            child: const Text('2',
                style: TextStyle(
                    color: Color(0xFFE04443),
                    fontSize: 12,
                    fontWeight: FontWeight.bold))),
      ]),
      Row(children: [
        Text('Lihat Semua',
            style: TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Icon(Icons.arrow_forward, color: _primaryGreen, size: 16),
      ]),
    ]);
  }

  Widget _buildWaitingOrderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Border dibuat sangat transparan agar tidak kaku
          border: Border.all(color: Colors.black.withOpacity(0.02)),
          boxShadow: [
            BoxShadow(
                color: Colors.black
                    .withOpacity(0.06), // Shadow lebih lembut dan menyebar
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8)) // Jatuh bayangannya ke bawah
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(
              radius: 24,
              backgroundImage:
                  NetworkImage('https://i.pravatar.cc/150?img=11')),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Budi Santoso',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.phone_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('0812-3456-7890',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13))
                ]),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('5 menit lalu',
                  style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5FE),
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: _primaryGreen),
                const SizedBox(width: 8),
                const Text('Futsal A',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('  â€¢  ', style: TextStyle(color: Colors.grey)),
                const Text('Sabtu, 30 Mar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.access_time, size: 16, color: _primaryGreen),
                const SizedBox(width: 8),
                const Text('19:00â€“20:00',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
              ]),
            ])),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Pembayaran',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            const Text('Rp 125.000',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Transfer BCA',
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ]),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _bgLightGreen, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.list_alt, size: 16, color: _primaryGreen),
                const SizedBox(width: 4),
                Text('Lihat Bukti',
                    style: TextStyle(
                        color: _primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ])),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: GestureDetector(
                  onTap: () {},
                  child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _bgLightRed,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('Tolak',
                          style: TextStyle(
                              color: _textRed,
                              fontWeight: FontWeight.w900,
                              fontSize: 16))))),
          const SizedBox(width: 12),
          Expanded(
              child: GestureDetector(
                  onTap: () {},
                  child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _primaryGreen,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Konfirmasi',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16))))),
        ]),
      ]),
    );
  }

  Widget _buildRevenueSummarySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ringkasan Pendapatan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pendapatan 7 Hari Terakhir',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Rp 3.2 Juta',
              style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMiniBar('Sen', 0.4),
                _buildMiniBar('Sel', 0.6),
                _buildMiniBar('Rab', 0.3),
                _buildMiniBar('Kam', 0.8),
                _buildMiniBar('Jum', 0.5),
                _buildMiniBar('Sab', 0.7),
                _buildMiniBar('Min', 0.9, isToday: true),
              ]),
        ]),
      ),
    ]);
  }

  Widget _buildMiniBar(String day, double heightFactor,
      {bool isToday = false}) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      if (isToday)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('Today',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10)),
        ),
      Container(
        width: 12,
        height: 80 * heightFactor,
        decoration: BoxDecoration(
          color: isToday ? _primaryGreen : Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      const SizedBox(height: 8),
      Text(day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? _primaryGreen : Colors.grey[500],
          )),
    ]);
  }
}
