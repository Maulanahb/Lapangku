import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/mitra/mitra_revenue_provider.dart';
import 'package:lapangku/models/mitra/mitra_revenue_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';

class MitraRevenuePage extends ConsumerStatefulWidget {
  const MitraRevenuePage({super.key});

  @override
  ConsumerState<MitraRevenuePage> createState() => _MitraRevenuePageState();
}

class _MitraRevenuePageState extends ConsumerState<MitraRevenuePage> {
  String _selectedFilter = 'Bulan Ini';

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(mitraRevenueProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pendapatan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
            onPressed: () {}, // Future: Custom range
          ),
        ],
      ),
      body: revenueAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Gagal memuat data',
          subtitle: err.toString(),
        ),
        data: (revenue) => RefreshIndicator(
          onRefresh: () => ref.read(mitraRevenueProvider.notifier).loadRevenue(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDescriptionText(),
                _buildHeroCard(revenue),
                _buildFilterChips(),
                _buildSectionTitle("Ringkasan"),
                _buildSummaryGrid(revenue),
                _buildSectionTitle("Tren Pendapatan"),
                _buildTrendCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Transaksi Terbaru",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeading,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Lihat Semua",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTransactionList(revenue.transactions),
                _buildPayoutStatus(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Text(
        "Pantau pemasukan booking dan pencairan pendapatan lapangan.",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildHeroCard(MitraRevenueModel revenue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 15, offset: Offset(0, 8)),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Pendapatan Bulan Ini",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text("18%", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox( // FIX: Gunakan FittedBox agar nominal tidak overflow
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(revenue.totalRevenue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "Dari ${revenue.totalOrders} booking selesai bulan ini", // FIX: Menggunakan data dinamis
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat("${revenue.totalOrders}", "BOOKING"), // FIX: Menggunakan totalOrders dinamis
              _buildMiniStat(
                CurrencyFormatter.formatShort( // FIX: Menggunakan formatShort untuk rata-rata
                  revenue.totalOrders > 0 ? (revenue.totalRevenue ~/ revenue.totalOrders) : 0,
                ).toUpperCase(),
                "RATA-RATA",
              ),
              _buildMiniStat("${(revenue.payoutSuccessRate * 100).toInt()}%", "PAYOUT BERHASIL"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Wrap( // FIX: Ganti SingleChildScrollView + Row menjadi Wrap agar tidak kepotong
        spacing: 12,
        runSpacing: 12,
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
                boxShadow: isSelected ? null : [const BoxShadow(color: AppColors.shadow, blurRadius: 4)],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textHeading,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(MitraRevenueModel revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1, // FIX: Kecilkan ratio (1.4 -> 1.1) agar card lebih tinggi untuk menampung teks
        children: [
          _buildDetailCard(
            "Pendapatan Hari Ini",
            CurrencyFormatter.format(revenue.todayRevenue),
            "+12% dari kemarin",
            Icons.account_balance_wallet,
            Colors.green,
          ),
          _buildDetailCard(
            "Menunggu Payout",
            CurrencyFormatter.format(revenue.pendingPayout),
            "Cair Senin depan",
            Icons.access_time,
            Colors.orange,
          ),
          _buildDetailCard(
            "Sudah Dicairkan",
            CurrencyFormatter.format(revenue.disbursedRevenue),
            "Berhasil diproses",
            Icons.check_circle_outline,
            AppColors.primary,
          ),
          _buildDetailCard(
            "Booking Aktif",
            "${revenue.activeBookings} Booking",
            "Hari ini",
            Icons.calendar_today,
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Text(
            title, 
            maxLines: 1, // FIX: Batasi baris agar tidak overflow
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)
          ),
          const SizedBox(height: 4),
          FittedBox( // FIX: Gunakan FittedBox agar nominal besar tidak overflow ke samping
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textHeading)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle, 
            maxLines: 1, // FIX: Batasi baris subtitle
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tren Pendapatan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("7 Hari Terakhir", style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: SimpleChartPainter(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            "Pendapatan tertinggi terjadi pada Sabtu - Rp 1.8 juta",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<MitraTransactionModel> transactions) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("Belum ada transaksi")),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: transactions.length > 5 ? 5 : transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.fieldName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(tx.customerName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      DateFormat('dd MMM yyyy - HH:mm').format(tx.date),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "+${CurrencyFormatter.format(tx.amount)}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Text("Selesai", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutStatus() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.account_balance, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Payout berikutnya diproses Senin, 1 April",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textHeading),
                ),
                Text(
                  "Pendapatan booking selesai akan otomatis dicairkan.",
                  style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ],
      ),
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.9, size.width * 0.4, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.3, size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.2);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    
    // Dot at current day
    final dotPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.4), 5, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.4), 8, Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
