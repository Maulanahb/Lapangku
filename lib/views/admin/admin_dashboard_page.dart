import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/views/admin/admin_fields_page.dart';
import 'package:lapangku/views/admin/admin_bookings_page.dart';
import 'package:lapangku/views/admin/admin_users_page.dart';
import 'package:lapangku/views/admin/admin_reports_page.dart';
import 'package:lapangku/views/admin/admin_payouts_page.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final pages = [
      const _DashboardBody(),
      const AdminUsersPage(),
      const AdminFieldsPage(),
      const AdminBookingsPage(),
      const AdminReportsPage(),
      const AdminPayoutsPage(),
    ];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: IndexedStack(
                index: _selectedNav,
                children: pages,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('LapangKu Panel Admin'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
      ),
      drawer: Drawer(child: _buildSidebar()),
      body: IndexedStack(
        index: _selectedNav,
        children: pages,
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stadium_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LapangKu',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: _primary,
                            letterSpacing: -0.5)),
                    Text('PRO PANEL',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            letterSpacing: 1.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _sidebarItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                _sidebarItem(1, Icons.people_outline_rounded, Icons.people_rounded, 'Kelola Pengguna'),
                _sidebarItem(2, Icons.domain_verification_rounded, Icons.domain_verification_rounded, 'Verifikasi Mitra'),
                _sidebarItem(3, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Daftar Pesanan'),
                _sidebarItem(4, Icons.analytics_outlined, Icons.analytics_rounded, 'Laporan Analistik'),
                _sidebarItem(5, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Pencairan Dana'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.red.withOpacity(0.05),
              ),
              child: ListTile(
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pushReplacementNamed(context, '/admin-login');
                },
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                title: const Text('Keluar',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = _selectedNav == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          setState(() => _selectedNav = index);
          if (MediaQuery.of(context).size.width < 800) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? _primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _primary.withOpacity(0.1) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(isSelected ? iconFilled : iconOutlined,
                  color: isSelected ? _primary : Colors.grey.shade500,
                  size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? _primary : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14,
                    letterSpacing: isSelected ? 0.2 : 0,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerStatefulWidget {
  const _DashboardBody();

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  static const _primary = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final dashboardStats = ref.watch(adminDashboardStatsProvider);
    
    final chartAsync = ref.watch(bookingsChartProvider);
    final activitiesAsync = ref.watch(activitiesProvider);
    final authState = ref.watch(authProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: _primary,
        onRefresh: () async {
          ref.read(adminStatsProvider.notifier).load();
          ref.read(bookingsChartProvider.notifier).load();
          ref.read(activitiesProvider.notifier).load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, authState.user?.nama ?? 'Admin'),
              const SizedBox(height: 32),
              
              dashboardStats.when(
                loading: () => _buildStatsShimmer(isDesktop),
                error: (error, _) => _buildError(error.toString()),
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(stats, isDesktop),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildChartCard(chartAsync)),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildDonutCard(stats)),
                        ],
                      )
                    else ...[
                      _buildChartCard(chartAsync),
                      const SizedBox(height: 24),
                      _buildDonutCard(stats),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              activitiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
                error: (_, __) => const SizedBox.shrink(),
                data: (activities) => _buildAktivitasTerbaru(context, activities),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String adminName) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final formatter = DateFormat('EEEE, d MMMM yyyy');
    final dateStr = formatter.format(DateTime.now());
    final mitrasAsync = ref.watch(adminAllMitrasProvider);
    final pendingCount = mitrasAsync.when(
      data: (list) => list.where((m) => m.statusVerifikasi == 'menunggu').length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isDesktop)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dashboard',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              )
            else
              const SizedBox.shrink(),

            Row(
              children: [
                // Notification Bell
                _NotificationBell(
                  pendingCount: pendingCount,
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                // Divider
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Profile Avatar with popup
                _ProfileMenu(adminName: adminName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminDashboardStats stats, bool isDesktop) {
    String fmt(int n) {
      if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)} jt';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} rb';
      return 'Rp $n';
    }

    final formatNumber = NumberFormat('#,##0', 'en_US');

    final cards = [
      _StatData(
        'TOTAL PENGGUNA',
        formatNumber.format(stats.totalPengguna),
        Icons.people_alt_outlined,
        const Color(0xFF1B6B3A),
        isGreen: false,
      ),
      _StatData(
        'TOTAL PEMILIK LAPANGAN',
        formatNumber.format(stats.totalMitra),
        Icons.stadium_outlined,
        const Color(0xFF4285F4),
        isGreen: false,
      ),
      _StatData(
        'TOTAL BOOKING HARI INI',
        formatNumber.format(stats.totalBookingHariIni),
        Icons.receipt_long_outlined,
        const Color(0xFFFF9800),
        isGreen: false,
      ),
      _StatData(
        'PENGHASILAN PLATFORM',
        fmt(stats.totalPendapatan),
        Icons.payments_outlined,
        Colors.white,
        isGreen: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 4;
        if (width < 600) {
          crossAxisCount = 1;
        } else if (width < 900) {
          crossAxisCount = 2;
        } else if (width < 1200) {
          crossAxisCount = 2; // Can be 2 or 3 depending on preference, 2 is safer for long text
        }

        // Account for spacing (crossAxisCount - 1) * 16
        // Small tolerance subtraction to prevent wrap due to rounding
        final cardWidth = (width - ((crossAxisCount - 1) * 16)) / crossAxisCount - 0.1;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((c) => SizedBox(
            width: cardWidth,
            child: _buildStatCard(c),
          )).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      decoration: BoxDecoration(
        color: data.isGreen ? _primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.isGreen ? Colors.white.withOpacity(0.2) : data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.isGreen ? Colors.white : data.color, size: 22),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 10,
                  color: data.isGreen ? Colors.white70 : Colors.grey.shade500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: data.isGreen ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsShimmer(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 4;
        if (width < 600) {
          crossAxisCount = 1;
        } else if (width < 900) {
          crossAxisCount = 2;
        } else if (width < 1200) {
          crossAxisCount = 2;
        }
        final cardWidth = (width - ((crossAxisCount - 1) * 16)) / crossAxisCount - 0.1;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(4, (_) => Container(
            width: cardWidth,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200, 
              borderRadius: BorderRadius.circular(12)
            ),
          )),
        );
      },
    );
  }

  Widget _buildChartCard(AsyncValue<List<int>> chartAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pesanan per Minggu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Row(
                children: [
                  _chartLegend(const Color(0xFF1B6B3A), 'Past 6 Days'),
                  const SizedBox(width: 12),
                  _chartLegend(const Color(0xFFFF9800), 'Today'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: chartAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
              error: (_, __) => const Center(child: Text('Gagal memuat grafik')),
              data: (data) => _buildBarChart(data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildBarChart(List<int> data) {
    final days = <String>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final formatter = DateFormat('EEE');
      days.add(formatter.format(d).toUpperCase());
    }

    final maxVal = data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 10.0 : maxVal.toDouble() + 5;

    return BarChart(BarChartData(
      maxY: maxY,
      barTouchData: const BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= days.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(days[idx], style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(data.length, (i) {
        final isToday = i == data.length - 1;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: data[i].toDouble(),
            color: isToday ? const Color(0xFFFF9800) : const Color(0xFF1B6B3A),
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ]);
      }),
    ));
  }

  Widget _buildDonutCard(AdminDashboardStats stats) {
    final selesai = stats.countSelesai;
    final menungguBayar = stats.countMenungguBayar;
    final menungguKonfirmasi = stats.countMenungguKonfirmasi;
    final dikonfirmasi = stats.countDikonfirmasi;
    final dibatalkan = stats.countDibatalkan;
    final total = selesai + menungguBayar + menungguKonfirmasi + dikonfirmasi + dibatalkan;

    double pct(int n) => total == 0 ? 0 : (n / total * 100);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 170,
              width: 170,
              child: Stack(alignment: Alignment.center, children: [
                PieChart(PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  startDegreeOffset: -90,
                  sections: total == 0
                    ? [PieChartSectionData(value: 100, color: Colors.grey.shade200, radius: 22, showTitle: false)]
                    : [
                      if (selesai > 0)         PieChartSectionData(value: pct(selesai), color: _primary, radius: 22, showTitle: false),
                      if (dikonfirmasi > 0)    PieChartSectionData(value: pct(dikonfirmasi), color: const Color(0xFF4285F4), radius: 22, showTitle: false),
                      if (menungguKonfirmasi > 0) PieChartSectionData(value: pct(menungguKonfirmasi), color: const Color(0xFF9C27B0), radius: 22, showTitle: false),
                      if (menungguBayar > 0)   PieChartSectionData(value: pct(menungguBayar), color: const Color(0xFFFF9800), radius: 22, showTitle: false),
                      if (dibatalkan > 0)      PieChartSectionData(value: pct(dibatalkan), color: Colors.red.shade400, radius: 22, showTitle: false),
                    ],
                )),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Color(0xFF1A1A2E))),
                  const Text('TOTAL', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          _legendItemPie(_primary,                  'Selesai', selesai, total),
          const SizedBox(height: 8),
          _legendItemPie(const Color(0xFF4285F4),   'Dikonfirmasi', dikonfirmasi, total),
          const SizedBox(height: 8),
          _legendItemPie(const Color(0xFF9C27B0),   'Menunggu Konfirmasi', menungguKonfirmasi, total),
          const SizedBox(height: 8),
          _legendItemPie(const Color(0xFFFF9800),   'Menunggu Bayar', menungguBayar, total),
          const SizedBox(height: 8),
          _legendItemPie(Colors.red.shade400,       'Dibatalkan/Ditolak', dibatalkan, total),
        ],
      ),
    );
  }

  Widget _legendItemPie(Color color, String label, int count, int total) {
    final pct = total == 0 ? 0 : (count / total * 100).round();
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ),
        Text(
          '$pct%',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildAktivitasTerbaru(BuildContext context, List<Map<String, dynamic>> activities) {
    final list = activities.take(5).toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aktivitas Terkini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              GestureDetector(
                onTap: () => _showAllActivities(context, activities),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.list_alt_rounded, size: 14, color: _primary),
                      SizedBox(width: 6),
                      Text('Lihat Semua', style: TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Belum ada aktivitas', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 100 > 800
                      ? MediaQuery.of(context).size.width - 400
                      : 800,
                ),
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: 28,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
                  columns: const [
                    DataColumn(label: Text('TANGGAL', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('PENGGUNA', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('AKSI', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('DETAIL', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                  ],
                  rows: list.map((b) => _buildDataRow(b)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> activity) {
    final String nama = activity['user'] as String? ?? '-';
    final inisial = nama.isNotEmpty ? nama.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase() : '?';
    final String status = activity['status'] as String? ?? 'menunggu';
    final statusColor = _statusColor(status);
    final DateTime time = activity['time'] as DateTime? ?? DateTime.now();
    final String tanggal = DateFormat('dd MMM yyyy').format(time);
    final bool isRegistration = activity['type'] == 'registration';

    return DataRow(
      cells: [
        DataCell(Text(
          tanggal,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        )),
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: isRegistration ? Colors.blue.shade50 : const Color(0xFFE8F5E9),
              child: Text(inisial, style: TextStyle(fontSize: 10, color: isRegistration ? Colors.blue.shade700 : _primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text(nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        )),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isRegistration ? Colors.blue.shade50 : _primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            activity['action'] as String? ?? '-',
            style: TextStyle(
              color: isRegistration ? Colors.blue.shade700 : _primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        )),
        DataCell(Text(
          activity['detail'] as String? ?? '-',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(
            _statusLabel(status),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        )),
      ],
    );
  }

  void _showAllActivities(BuildContext context, List<Map<String, dynamic>> activities) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 780,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Semua Aktivitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A2E))),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${activities.length} aktivitas terbaru', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    horizontalMargin: 0,
                    columnSpacing: 24,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
                    columns: const [
                      DataColumn(label: Text('TANGGAL', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('PENGGUNA', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('AKSI', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('DETAIL', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    ],
                    rows: activities.map((a) => _buildDataRow(a)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Color _statusColor(String status) {
    switch (status) {
      case 'selesai': return const Color(0xFF1B6B3A);
      case 'aktif':   return const Color(0xFF1B6B3A);
      case 'dikonfirmasi': return const Color(0xFF4285F4);
      case 'menunggu_konfirmasi': return const Color(0xFF9C27B0);
      case 'menunggu_bayar': return const Color(0xFFFF9800);
      case 'dibatalkan': return Colors.red.shade400;
      case 'ditolak':    return Colors.red.shade400;
      case 'expired':    return Colors.red.shade300;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'selesai':              return 'Selesai';
      case 'aktif':               return 'Aktif';
      case 'dikonfirmasi':        return 'Dikonfirmasi';
      case 'menunggu_konfirmasi': return 'Menunggu Konfirmasi';
      case 'menunggu_bayar':      return 'Menunggu Bayar';
      case 'dibatalkan':          return 'Dibatalkan';
      case 'ditolak':             return 'Ditolak';
      case 'expired':             return 'Expired';
      case 'menunggu':            return 'Menunggu';
      default: return status;
    }
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text('Error: $msg', style: const TextStyle(color: Colors.red)),
    );
  }
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isGreen;
  const _StatData(this.label, this.value, this.icon, this.color, {this.isGreen = false});
}

// ─── Notification Bell Widget ────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;
  const _NotificationBell({required this.pendingCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined, color: Colors.grey.shade600, size: 22),
            if (pendingCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    pendingCount > 9 ? '9+' : '$pendingCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Menu Widget ─────────────────────────────────────────────────────
class _ProfileMenu extends ConsumerWidget {
  final String adminName;
  const _ProfileMenu({required this.adminName});

  static const _primary = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inisial = adminName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _primary,
              child: Text(
                inisial,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(adminName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1A2E))),
                Text('Administrator',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _primary,
                    child: Text(inisial,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adminName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
                      Text('admin@lapangku.id',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, height: 1),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Keluar',
                  style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authProvider.notifier).logout();
          Navigator.pushReplacementNamed(context, '/admin-login');
        }
      },
    );
  }
}
