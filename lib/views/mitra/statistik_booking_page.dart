import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/mitra/mitra_stats_controller.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';

class StatistikBookingPage extends ConsumerStatefulWidget {
  const StatistikBookingPage({super.key});

  @override
  ConsumerState<StatistikBookingPage> createState() => _StatistikBookingPageState();
}

class _StatistikBookingPageState extends ConsumerState<StatistikBookingPage> {
  @override
  Widget build(BuildContext context) {
    final mitraId = ref.watch(currentUidProvider);
    final statsAsync = ref.watch(mitraAdvancedStatsProvider(mitraId));
    final currentFilter = ref.watch(statsFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Statistik Booking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

      ),
      body: Builder(
        builder: (context) {
          if (statsAsync['isLoading'] == true) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          
          if (statsAsync['error'] != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Gagal Memuat Data',
              subtitle: statsAsync['error'].toString(),
              actionButton: ElevatedButton(
                onPressed: () => ref.refresh(mitraBookingsProvider(mitraId)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            );
          }

          final stats = statsAsync;


          return RefreshIndicator(
            onRefresh: () async => ref.refresh(mitraBookingsProvider(mitraId)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- DESKRIPSI ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'Lihat aktivitas booking dan performa lapangan secara singkat untuk mengoptimalkan bisnis Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // --- HERO CARD (Total Booking) ---
                  _buildHeroCard(stats),

                  // --- FILTER CHIPS ---
                  _buildFilterChips(currentFilter),

                  const SizedBox(height: 12),

                  // --- GRID STATISTIK (2x2) ---
                  _buildStatsGrid(stats),

                  const SizedBox(height: 24),

                  // --- SECTION AKTIVITAS MINGGUAN ---
                  _buildWeeklyActivity(stats),

                  const SizedBox(height: 24),

                  // --- SECTION SLOT JAM TERPOPULER ---
                  _buildPopularSlots(stats),

                  const SizedBox(height: 24),

                  // --- SECTION LAPANGAN PALING AKTIF ---
                  _buildMostActiveField(stats),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total booking berhasil',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${stats['totalSuccess'] ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      stats['growth'] ?? '+0%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStatItem('${stats['todayCount'] ?? 0}', 'HARI INI'),
              _buildSmallStatItem('${stats['attendanceRate'] ?? 0}%', 'KEHADIRAN', isGreen: true),
              _buildSmallStatItem(stats['peakHour'] ?? '00:00', 'JAM RAMAI'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatItem(String value, String label, {bool isGreen = false}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isGreen ? Colors.greenAccent : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(StatsFilter currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildChip(StatsFilter.hariIni, 'Hari Ini', currentFilter),
          const SizedBox(width: 8),
          _buildChip(StatsFilter.mingguIni, 'Minggu Ini', currentFilter),
          const SizedBox(width: 8),
          _buildChip(StatsFilter.bulanIni, 'Bulan Ini', currentFilter),
          const SizedBox(width: 8),
          _buildChip(StatsFilter.tahunIni, 'Tahun Ini', currentFilter),
        ],
      ),
    );
  }

  Widget _buildChip(StatsFilter filter, String label, StatsFilter currentFilter) {
    final isActive = filter == currentFilter;
    return GestureDetector(
      onTap: () => ref.read(statsFilterProvider.notifier).state = filter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderLight,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.6, // FIX: BUG 1 - childAspectRatio ditingkatkan ke 1.6
        children: [
          _buildGridItem('Booking Aktif', '${stats['activeCount'] ?? 0}', Icons.calendar_month, Colors.blue),
          _buildGridItem('Booking Selesai', '${stats['finishedCount'] ?? 0}', Icons.check_circle_outline, Colors.green),
          _buildGridItem('Jam Teramai', stats['peakHour'] ?? '00:00', Icons.access_time, Colors.orange),
          _buildGridItem('Booking Batal', '${stats['cancelledCount'] ?? 0}', Icons.cancel_outlined, Colors.red),
        ],
      ),
    );
  }

  Widget _buildGridItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textHeading,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivity(Map<String, dynamic> stats) {
    final weeklyData = (stats['weeklyActivity'] as List? ?? []);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Mingguan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map<Widget>((data) {
                int maxCount = 0;
                for (var d in weeklyData) {
                  if (d['count'] > maxCount) maxCount = d['count'];
                }
                double heightFactor = maxCount > 0 ? (data['count'] / maxCount) : 0;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: (120 * heightFactor).clamp(4.0, 120.0),
                      decoration: BoxDecoration(
                        color: data['isSaturday'] == true ? AppColors.primary : AppColors.primaryLight.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['day'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: data['isSaturday'] == true ? FontWeight.bold : FontWeight.normal,
                        color: data['isSaturday'] == true ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_graph, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Booking paling ramai terjadi pada Sabtu.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSlots(Map<String, dynamic> stats) {
    final popularSlots = (stats['popularSlots'] as List? ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Slot Jam Terpopuler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeading,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Detail', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: popularSlots.map<Widget>((slot) {
                final double progress = (slot['percentage'] as int) / 100;
                Color progressColor = Colors.green;
                if (progress < 0.7) progressColor = Colors.orange;
                if (progress < 0.4) progressColor = Colors.red;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            slot['slot'],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${slot['percentage']}% Full',
                            style: TextStyle(
                              color: progressColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.backgroundPage,
                          color: progressColor,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostActiveField(Map<String, dynamic> stats) {
    final fieldData = stats['mostActiveField'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lapangan Paling Aktif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/placeholder_field.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fieldData['name'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              fieldData['badge'] ?? '',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fieldData['count'] ?? 0} booking bulan ini',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < 3 ? AppColors.primary : AppColors.borderLight,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
