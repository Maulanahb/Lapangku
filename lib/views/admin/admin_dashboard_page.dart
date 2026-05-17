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

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  static const _primary = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final bookingsAsync = ref.watch(adminAllBookingsProvider);
    final fieldsAsync = ref.watch(adminAllFieldsProvider);
    final dashboardStats = ref.watch(adminDashboardStatsProvider);
    
    final chartAsync = ref.watch(bookingsChartProvider);
    final activitiesAsync = ref.watch(activitiesProvider);
    final authState = ref.watch(authProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: _primary,
        onRefresh: () async {
          ref.refresh(adminAllBookingsProvider);
          ref.refresh(adminAllFieldsProvider);
          ref.read(bookingsChartProvider.notifier).load();
          ref.read(activitiesProvider.notifier).load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref, authState.user?.nama ?? 'Admin'),
              const SizedBox(height: 32),
              
              if (bookingsAsync.isLoading || fieldsAsync.isLoading)
                _buildStatsShimmer(isDesktop)
              else if (bookingsAsync.hasError || fieldsAsync.hasError)
                _buildError(bookingsAsync.error?.toString() ?? fieldsAsync.error.toString())
              else
                _buildStatsGrid(dashboardStats, isDesktop),
              const SizedBox(height: 24),
              
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildChartCard(chartAsync)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildDonutCardWrap(bookingsAsync)),
                  ],
                )
              else ...[
                _buildChartCard(chartAsync),
                const SizedBox(height: 24),
                _buildDonutCardWrap(bookingsAsync),
              ],
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, String adminName) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final formatter = DateFormat('EEEE, d MMMM yyyy');
    final dateStr = formatter.format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isDesktop)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          )
        else
          const SizedBox.shrink(),
        
        Row(
          children: [
            if (isDesktop) ...[
              Container(
                width: 250,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search data, fields, or users...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Stack(children: [
              IconButton(icon: const Icon(Icons.notifications_none, color: Colors.grey), onPressed: () {}),
              Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
            ]),
            IconButton(icon: const Icon(Icons.help_outline, color: Colors.grey), onPressed: () {}),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: _primary.withOpacity(0.15),
              child: const Icon(Icons.person, color: _primary, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(AdminDashboardStats stats, bool isDesktop) {
    String fmt(int n) {
      if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)} jt';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} rb';
      return 'Rp $n';
    }

    final cards = [
      _StatData('TOTAL LAPANGAN', stats.totalLapangan.toString(), Icons.stadium, const Color(0xFF1B6B3A), isGreen: false),
      _StatData('TRANSAKSI BERHASIL', stats.totalBookingSelesai.toString(), Icons.receipt_long, const Color(0xFF4285F4), isGreen: false),
      _StatData('PENDAPATAN PLATFORM', fmt(stats.totalPendapatan), Icons.payments, Colors.white, isGreen: true),
    ];

    return GridView.count(
      crossAxisCount: isDesktop ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isDesktop ? 2.5 : 2.5,
      children: cards.map((c) => _buildStatCard(c)).toList(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.isGreen ? Colors.white.withOpacity(0.2) : data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.isGreen ? Colors.white : data.color, size: 20),
              ),
              if (data.subtext != null)
                Text(
                  data.subtext!,
                  style: TextStyle(
                    color: data.isGreen ? Colors.white70 : (data.subtext!.contains('+') ? Colors.green : Colors.grey),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 10,
                  color: data.isGreen ? Colors.white70 : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
    return GridView.count(
      crossAxisCount: isDesktop ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isDesktop ? 2.5 : 2.5,
      children: List.generate(3, (_) => Container(decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)))),
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
              const Text('Pesanan per Tahun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildDonutCardWrap(AsyncValue bookingsAsync) {
    return bookingsAsync.when(
      loading: () => Container(height: 334, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
      error: (_, __) => const SizedBox.shrink(),
      data: (bookings) => _buildDonutCard(bookings),
    );
  }

  Widget _buildDonutCard(bookings) {
    final list = bookings as List;
    final berhasil = list.where((b) => b.status == 'selesai').length;
    final menunggu = list.where((b) => b.status == 'menunggu').length;
    final dikonfirmasi = list.where((b) => b.status == 'dikonfirmasi').length;
    final dibatalkan = list.where((b) => b.status == 'dibatalkan').length;
    final total = list.length;

    final pb = total == 0 ? 0 : (berhasil / total * 100).round();
    final pdk = total == 0 ? 0 : (dikonfirmasi / total * 100).round();
    final pm = total == 0 ? 0 : (menunggu / total * 100).round();
    final pdb = total == 0 ? 0 : (dibatalkan / total * 100).round();

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
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(alignment: Alignment.center, children: [
                PieChart(PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 65,
                  startDegreeOffset: -90,
                  sections: total == 0 
                  ? [PieChartSectionData(value: 100, color: Colors.grey.shade300, radius: 20, showTitle: false)]
                  : [
                    if (pb > 0) PieChartSectionData(value: pb.toDouble(), color: _primary, radius: 20, showTitle: false),
                    if (pdk > 0) PieChartSectionData(value: pdk.toDouble(), color: const Color(0xFF4285F4), radius: 20, showTitle: false),
                    if (pdb > 0) PieChartSectionData(value: pdb.toDouble(), color: Colors.red, radius: 20, showTitle: false),
                    if (pm > 0) PieChartSectionData(value: pm.toDouble(), color: const Color(0xFFFF9800), radius: 20, showTitle: false),
                  ],
                )),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(total.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Color(0xFF1A1A2E))),
                  const Text('TOTAL', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItemPie(_primary, 'Completed ($pb%)'),
                  const SizedBox(height: 12),
                  _legendItemPie(const Color(0xFFFF9800), 'Pending ($pm%)'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItemPie(const Color(0xFF4285F4), 'Ongoing ($pdk%)'),
                  const SizedBox(height: 12),
                  _legendItemPie(Colors.red, 'Cancelled ($pdb%)'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItemPie(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildAktivitasTerbaru(BuildContext context, List<Map<String, dynamic>> activities) {
    final list = activities.take(5).toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Aktivitas Terkini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Lihat Semua Aktivitas', style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          if (list.isEmpty)
            const Center(child: Text('Belum ada aktivitas'))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100 > 800 ? MediaQuery.of(context).size.width - 400 : 800),
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: 32,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
                  columns: const [
                    DataColumn(label: Text('TIME', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('USER', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
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
    final String nama = activity['user'] as String;
    final inisial = nama.isNotEmpty ? nama.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase() : '?';
    final statusColor = _statusColor(activity['status'] as String);
    final DateTime time = activity['time'] as DateTime;
    final String jam = DateFormat('HH:mm').format(time);
    final isRegistration = activity['type'] == 'registration';
    
    return DataRow(
      cells: [
        DataCell(Text(jam, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        DataCell(Row(
          children: [
            CircleAvatar(radius: 14, backgroundColor: const Color(0xFFE8F5E9), child: Text(inisial, style: const TextStyle(fontSize: 10, color: _primary, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Text(nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        )),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isRegistration ? Colors.blue.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            activity['action'] as String,
            style: TextStyle(
              color: isRegistration ? Colors.blue.shade700 : Colors.grey.shade700,
              fontSize: 13,
              fontWeight: isRegistration ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        )),
        DataCell(Text(activity['detail'] as String, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
          child: Text(_statusLabel(activity['status'] as String).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai':
      case 'aktif': return const Color(0xFF1B6B3A);
      case 'dikonfirmasi': return const Color(0xFF4285F4);
      case 'dibatalkan':
      case 'ditolak': return Colors.red;
      default: return const Color(0xFFFF9800);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'selesai': return 'Completed';
      case 'aktif': return 'Verified';
      case 'dibatalkan': return 'Cancelled';
      case 'ditolak': return 'Rejected';
      case 'dikonfirmasi': return 'Confirmed';
      case 'menunggu': return 'Pending';
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
  final String? subtext;
  final bool isGreen;
  const _StatData(this.label, this.value, this.icon, this.color,
      {this.isGreen = false});
}
