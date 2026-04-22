import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/admin/admin_stats.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  static const _primary = Color(0xFF1B6B3A);
  int _selectedNav = 0;

  final _pages = [
    const _DashboardBody(),
    const Scaffold(body: Center(child: Text('Coming Soon'))),
    const Scaffold(body: Center(child: Text('Coming Soon'))),
    const Scaffold(body: Center(child: Text('Coming Soon'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _pages[_selectedNav],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNav,
        onTap: (i) => setState(() => _selectedNav = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primary,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Lapangan'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Pengguna'),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  static const _primary = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final chartAsync = ref.watch(bookingsChartProvider);
    final bookingsAsync = ref.watch(bookingsProvider);

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
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Icon(Icons.menu, size: 24),
                const Text('Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
                Row(children: [
                  Stack(children: [
                    const Icon(Icons.notifications_outlined, size: 26),
                    Positioned(right: 0, top: 0,
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                  ]),
                  const SizedBox(width: 10),
                  const CircleAvatar(radius: 18, backgroundColor: _primary, child: Icon(Icons.person, color: Colors.white, size: 20)),
                ]),
              ]),
              const SizedBox(height: 20),

              // Stats Grid
              statsAsync.when(
                loading: () => _buildStatsShimmer(),
                error: (e, _) => _buildError(e.toString()),
                data: (stats) => _buildStatsGrid(stats),
              ),
              const SizedBox(height: 20),

              // Bar Chart
              _buildChartCard(chartAsync),
              const SizedBox(height: 20),

              // Donut Chart
              bookingsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (bookings) => _buildDonutCard(bookings),
              ),
              const SizedBox(height: 20),

              // Aktivitas Terbaru
              bookingsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (bookings) => _buildAktivitasTerbaru(context, bookings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminStats stats) {
    String formatAngka(int n) {
      if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)}jt';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}rb';
      return n.toString();
    }

    final cards = [
      _StatData('Total Pengguna', stats.totalUsers.toString(), Icons.people_alt_outlined, const Color(0xFF4FC3F7)),
      _StatData('Lapangan Aktif', stats.lapanganAktif.toString(), Icons.sports_soccer, const Color(0xFF81C784)),
      _StatData('Pesanan Hari Ini', stats.pesananHariIni.toString(), Icons.receipt_outlined, const Color(0xFFFFB74D)),
      _StatData('Pendapatan', 'Rp ${formatAngka(stats.totalPendapatan)}', Icons.attach_money, const Color(0xFF80CBC4)),
    ];

    return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
      children: cards.map((c) => _buildStatCard(c)).toList());
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(data.icon, color: data.color, size: 28),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.label.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 0.5, fontWeight: FontWeight.w500)),
          Text(data.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        ]),
      ]),
    );
  }

  Widget _buildStatsShimmer() {
    return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
      children: List.generate(4, (_) => Container(decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)))));
  }

  Widget _buildChartCard(AsyncValue<List<int>> chartAsync) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Pesanan per Hari (7 hari)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Icon(Icons.more_vert, color: Colors.grey[400]),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 160, child: chartAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
          error: (_, __) => const Center(child: Text('Gagal memuat grafik')),
          data: (data) => _buildBarChart(data),
        )),
      ]),
    );
  }

  Widget _buildBarChart(List<int> data) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final maxY = data.isEmpty ? 10.0 : data.reduce((a, b) => a > b ? a : b).toDouble() + 2;

    return BarChart(BarChartData(
      maxY: maxY, barTouchData: const BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
          final idx = value.toInt();
          if (idx < 0 || idx >= days.length) return const SizedBox();
          return Text(days[idx], style: const TextStyle(fontSize: 11, color: Colors.grey));
        })),
      ),
      gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
      barGroups: List.generate(data.length, (i) {
        final isMax = data[i] == data.reduce((a, b) => a > b ? a : b);
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: data[i].toDouble(), color: isMax ? _primary : _primary.withOpacity(0.35),
            width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
        ]);
      }),
    ));
  }

  Widget _buildDonutCard(bookings) {
    final list = bookings as List;
    final berhasil = list.where((b) => b.status == 'selesai').length;
    final menunggu = list.where((b) => b.status == 'menunggu').length;
    final dibatalkan = list.where((b) => b.status == 'dibatalkan').length;
    final total = list.length;
    final persenBerhasil = total == 0 ? 0 : ((berhasil / total) * 100).round();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(height: 120, width: 120, child: Stack(alignment: Alignment.center, children: [
            PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 36, sections: [
              PieChartSectionData(value: berhasil.toDouble(), color: _primary, radius: 22, showTitle: false),
              PieChartSectionData(value: menunggu.toDouble(), color: const Color(0xFFFFB74D), radius: 22, showTitle: false),
              PieChartSectionData(value: dibatalkan.toDouble(), color: Colors.grey[300]!, radius: 22, showTitle: false),
            ])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$persenBerhasil%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('SUKSES', style: TextStyle(fontSize: 9, color: Colors.grey)),
            ]),
          ])),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _legendItem(_primary, 'Berhasil'), const SizedBox(height: 8),
            _legendItem(const Color(0xFFFFB74D), 'Menunggu'), const SizedBox(height: 8),
            _legendItem(Colors.grey.shade300, 'Dibatalkan'),
          ]),
        ]),
      ]),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13)),
    ]);
  }

  Widget _buildAktivitasTerbaru(BuildContext context, dynamic bookings) {
    final list = (bookings as List).take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Aktivitas Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        GestureDetector(onTap: () {},
          child: const Text('Lihat Semua', style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: list.isEmpty
            ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada aktivitas')))
            : Column(children: list.asMap().entries.map((entry) {
                final i = entry.key; final b = entry.value; final isLast = i == list.length - 1;
                return _buildAktivitasItem(b, isLast);
              }).toList()),
      ),
    ]);
  }

  Widget _buildAktivitasItem(dynamic booking, bool isLast) {
    final nama = booking.namaPenyewa as String;
    final inisial = nama.isNotEmpty ? nama.trim().split(' ').map((w) => w[0]).take(2).join() : '?';
    final statusColor = _statusColor(booking.status as String);
    final jam = '${booking.tanggal.hour.toString().padLeft(2, '0')}:${booking.tanggal.minute.toString().padLeft(2, '0')} WIB';

    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          CircleAvatar(backgroundColor: _primary.withOpacity(0.15),
            child: Text(inisial.toUpperCase(), style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('Memesan ${booking.namaLapangan}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(_statusLabel(booking.status as String),
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            Text(jam, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ])),
      if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
    ]);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai': return Colors.green;
      case 'dikonfirmasi': return const Color(0xFF2196F3);
      case 'dibatalkan': return Colors.red;
      default: return const Color(0xFFFFB74D);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'selesai': return 'Sukses';
      case 'dibatalkan': return 'Dibatalkan';
      case 'dikonfirmasi': return 'Dikonfirmasi';
      default: return 'Menunggu';
    }
  }

  Widget _buildError(String msg) {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text('Error: $msg', style: const TextStyle(color: Colors.red)));
  }
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}
