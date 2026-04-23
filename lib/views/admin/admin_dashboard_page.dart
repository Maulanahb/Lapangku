import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/admin/admin_stats.dart';
import 'package:lapangku/views/admin/admin_fields_page.dart';
import 'package:lapangku/views/admin/admin_bookings_page.dart';
import 'package:lapangku/views/admin/admin_users_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  static const _primary = Color(0xFF1B6B3A);
  int _selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardBody(),
      const AdminFieldsPage(),
      const AdminBookingsPage(),
      const AdminUsersPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(
        index: _selectedNav,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNav,
          onTap: (i) => setState(() => _selectedNav = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _primary,
          unselectedItemColor: const Color(0xFFADB5BD),
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer_outlined),
              activeIcon: Icon(Icons.sports_soccer),
              label: 'Lapangan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Pengguna',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Body
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  static const _primary = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final chartAsync = ref.watch(bookingsChartProvider);
    final bookingsAsync = ref.watch(bookingsProvider);
    final authState = ref.watch(authProvider);

    final adminName = authState.user?.nama ?? 'Admin';

    return SafeArea(
      child: RefreshIndicator(
        color: _primary,
        onRefresh: () async {
          ref.read(adminStatsProvider.notifier).load();
          ref.read(bookingsChartProvider.notifier).load();
          ref.read(bookingsProvider.notifier).load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ─────────────────────────────────────────────────
              _buildHeader(context, ref, adminName),
              const SizedBox(height: 20),

              // ─── Welcome Banner ──────────────────────────────────────────
              _buildWelcomeBanner(adminName),
              const SizedBox(height: 20),

              // ─── Stats Grid ──────────────────────────────────────────────
              statsAsync.when(
                loading: () => _buildStatsShimmer(),
                error: (e, _) => _buildError(e.toString()),
                data: (stats) => _buildStatsGrid(stats),
              ),
              const SizedBox(height: 20),

              // ─── Bar Chart ───────────────────────────────────────────────
              _buildChartCard(chartAsync),
              const SizedBox(height: 20),

              // ─── Donut Chart ─────────────────────────────────────────────
              bookingsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (bookings) => _buildDonutCard(bookings),
              ),
              const SizedBox(height: 20),

              // ─── Aktivitas Terbaru ───────────────────────────────────────
              bookingsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: _primary)),
                error: (_, __) => const SizedBox.shrink(),
                data: (bookings) =>
                    _buildAktivitasTerbaru(context, bookings),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String adminName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_soccer,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'LapangKu',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
          ],
        ),
        Row(
          children: [
            Stack(children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    size: 26, color: Color(0xFF4A5568)),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle)),
              ),
            ]),
            GestureDetector(
              onTap: () => _showLogoutDialog(context, ref),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _primary.withOpacity(0.15),
                child: const Icon(Icons.person, color: _primary, size: 20),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(String adminName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6B3A), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B6B3A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  adminName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau dan kelola seluruh aktivitas platform',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdminStats stats) {
    String fmt(int n) {
      if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)}jt';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}rb';
      return n.toString();
    }

    final cards = [
      _StatData('Total Pengguna', stats.totalUsers.toString(),
          Icons.people_alt_outlined, const Color(0xFF4FC3F7)),
      _StatData('Lapangan Aktif', stats.lapanganAktif.toString(),
          Icons.sports_soccer, const Color(0xFF81C784)),
      _StatData('Pesanan Hari Ini', stats.pesananHariIni.toString(),
          Icons.receipt_outlined, const Color(0xFFFFB74D)),
      _StatData('Pendapatan', 'Rp ${fmt(stats.totalPendapatan)}',
          Icons.attach_money, const Color(0xFF80CBC4)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards.map((c) => _buildStatCard(c)).toList(),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(AsyncValue<List<int>> chartAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pesanan 7 Hari Terakhir',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
              ),
              Icon(Icons.bar_chart_rounded, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: chartAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _primary)),
              error: (_, __) =>
                  const Center(child: Text('Gagal memuat grafik')),
              data: (data) => _buildBarChart(data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<int> data) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final maxY = data.isEmpty
        ? 10.0
        : data.reduce((a, b) => a > b ? a : b).toDouble() + 2;
    final maxVal = data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b);

    return BarChart(BarChartData(
      maxY: maxY,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${data[group.x.toInt()]} pesanan',
              const TextStyle(color: Colors.white, fontSize: 12),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= days.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(days[idx],
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.1),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(data.length, (i) {
        final isMax = data[i] == maxVal && maxVal > 0;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: data[i].toDouble(),
            color: isMax ? _primary : _primary.withOpacity(0.3),
            width: 26,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ]);
      }),
    ));
  }

  Widget _buildDonutCard(bookings) {
    final list = bookings as List;
    final berhasil = list.where((b) => b.status == 'selesai').length;
    final menunggu = list.where((b) => b.status == 'menunggu').length;
    final dikonfirmasi =
        list.where((b) => b.status == 'dikonfirmasi').length;
    final dibatalkan = list.where((b) => b.status == 'dibatalkan').length;
    final total = list.length;
    final persenBerhasil =
        total == 0 ? 0 : ((berhasil / total) * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Pesanan',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 130,
                width: 130,
                child: Stack(alignment: Alignment.center, children: [
                  PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    sections: [
                      PieChartSectionData(
                          value: berhasil.toDouble(),
                          color: _primary,
                          radius: 24,
                          showTitle: false),
                      PieChartSectionData(
                          value: menunggu.toDouble(),
                          color: const Color(0xFFFFB74D),
                          radius: 24,
                          showTitle: false),
                      PieChartSectionData(
                          value: dikonfirmasi.toDouble(),
                          color: const Color(0xFF2196F3),
                          radius: 24,
                          showTitle: false),
                      PieChartSectionData(
                          value: dibatalkan.toDouble(),
                          color: Colors.grey.shade300,
                          radius: 24,
                          showTitle: false),
                    ],
                  )),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '$persenBerhasil%',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Text('SUKSES',
                        style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ]),
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(_primary, 'Selesai', berhasil),
                    const SizedBox(height: 8),
                    _legendItem(const Color(0xFF2196F3), 'Dikonfirmasi',
                        dikonfirmasi),
                    const SizedBox(height: 8),
                    _legendItem(
                        const Color(0xFFFFB74D), 'Menunggu', menunggu),
                    const SizedBox(height: 8),
                    _legendItem(
                        Colors.grey.shade300, 'Dibatalkan', dibatalkan),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text(
          count.toString(),
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAktivitasTerbaru(BuildContext context, dynamic bookings) {
    final list = (bookings as List).take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E)),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Belum ada aktivitas')))
              : Column(
                  children: list.asMap().entries.map((entry) {
                    final i = entry.key;
                    final b = entry.value;
                    final isLast = i == list.length - 1;
                    return _buildAktivitasItem(b, isLast);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildAktivitasItem(dynamic booking, bool isLast) {
    final nama = booking.namaPenyewa as String;
    final inisial = nama.isNotEmpty
        ? nama
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    final statusColor = _statusColor(booking.status as String);
    final jam =
        '${booking.tanggal.hour.toString().padLeft(2, '0')}:${booking.tanggal.minute.toString().padLeft(2, '0')} WIB';

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: _primary.withOpacity(0.12),
            child: Text(inisial,
                style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nama,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text('Memesan ${booking.namaLapangan}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusLabel(booking.status as String),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(jam,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ]),
      ),
      if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
    ]);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai':
        return Colors.green;
      case 'dikonfirmasi':
        return const Color(0xFF2196F3);
      case 'dibatalkan':
        return Colors.red;
      default:
        return const Color(0xFFFFB74D);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      default:
        return 'Menunggu';
    }
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('Error: $msg', style: const TextStyle(color: Colors.red)),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/admin-login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}
