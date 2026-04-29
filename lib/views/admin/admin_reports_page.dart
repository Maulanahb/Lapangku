import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/admin/booking_model.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  static const _primary = Color(0xFF1B6B3A);
  String _selectedReportType = 'Booking'; // 'Booking' or 'Penghasilan'

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (bookings) => _buildReportContent(bookings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Laporan Statistik',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Analisis performa platform berdasarkan data transaksi dan booking.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          _buildTabItem('Laporan Booking', 'Booking'),
          const SizedBox(width: 12),
          _buildTabItem('Laporan Penghasilan', 'Penghasilan'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, String type) {
    final isSelected = _selectedReportType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedReportType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(List<BookingModel> bookings) {
    if (_selectedReportType == 'Booking') {
      return _buildBookingReport(bookings);
    } else {
      return _buildRevenueReport(bookings);
    }
  }

  Widget _buildBookingReport(List<BookingModel> bookings) {
    final total = bookings.length;
    final selesai = bookings.where((b) => b.status == 'selesai').length;
    final batal = bookings.where((b) => b.status == 'dibatalkan').length;
    final successRate = total == 0 ? 0 : (selesai / total * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Total Booking', total.toString(), Icons.book_online, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Selesai', selesai.toString(), Icons.check_circle_outline, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Dibatalkan', batal.toString(), Icons.cancel_outlined, Colors.red)),
            ],
          ),
          const SizedBox(height: 24),
          _buildChartSection('Tren Booking (Bulanan)', _getMonthlyBookingData(bookings), 'Total Booking'),
          const SizedBox(height: 24),
          _buildDetailTable(bookings, isRevenue: false),
        ],
      ),
    );
  }

  Widget _buildRevenueReport(List<BookingModel> bookings) {
    final completedBookings = bookings.where((b) => b.status == 'selesai').toList();
    final totalRevenue = completedBookings.fold<int>(0, (sum, b) => sum + b.totalHarga);
    final avgRevenue = completedBookings.isEmpty ? 0 : (totalRevenue / completedBookings.length).round();
    
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Total Penghasilan', currencyFormat.format(totalRevenue), Icons.payments_outlined, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Rata-rata/Booking', currencyFormat.format(avgRevenue), Icons.trending_up, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Transaksi Berhasil', completedBookings.length.toString(), Icons.confirmation_number_outlined, Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          _buildChartSection('Tren Penghasilan (Bulanan)', _getMonthlyRevenueData(bookings), 'Penghasilan (dalam Juta)'),
          const SizedBox(height: 24),
          _buildDetailTable(completedBookings, isRevenue: true),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title, List<double> data, String yAxisLabel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                        if (value.toInt() >= 0 && value.toInt() < 12) {
                          return Text(months[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
                    isCurved: true,
                    color: _primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: _primary.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTable(List<BookingModel> bookings, {required bool isRevenue}) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              isRevenue ? 'Rincian Transaksi Selesai' : 'Rincian Booking Terbaru',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FA)),
                dataRowMaxHeight: 64,
                dataRowMinHeight: 64,
                horizontalMargin: 24,
                columnSpacing: 24,
                columns: [
                  const DataColumn(label: Text('TANGGAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)))),
                  const DataColumn(label: Text('LAPANGAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)))),
                  const DataColumn(label: Text('PENYEWA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)))),
                  if (isRevenue) const DataColumn(label: Text('NOMINAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)))),
                  if (!isRevenue) const DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)))),
                ],
                rows: bookings.take(10).map((b) {
                  return DataRow(cells: [
                    DataCell(Text(dateFormat.format(b.tanggal), style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)))),
                    DataCell(Text(b.namaLapangan.isEmpty ? '-' : b.namaLapangan, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    DataCell(Text(b.namaPenyewa.isEmpty ? '-' : b.namaPenyewa, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
                    if (isRevenue) DataCell(Text(currencyFormat.format(b.totalHarga), style: const TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 13))),
                    if (!isRevenue) DataCell(_buildStatusChip(b.status)),
                  ]);
                }).toList(),
              ),
            ),
          ),
          if (bookings.isEmpty)
             const Padding(
               padding: EdgeInsets.all(32.0),
               child: Center(child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey))),
             ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'selesai': color = Colors.green; break;
      case 'dibatalkan': color = Colors.red; break;
      case 'dikonfirmasi': color = Colors.blue; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  List<double> _getMonthlyBookingData(List<BookingModel> bookings) {
    // Dummy grouping for demo purposes, in real app group by b.tanggal.month
    final counts = List.filled(12, 0.0);
    for (var b in bookings) {
      final month = b.tanggal.month - 1;
      if (month >= 0 && month < 12) counts[month] += 1;
    }
    return counts;
  }

  List<double> _getMonthlyRevenueData(List<BookingModel> bookings) {
    final revenue = List.filled(12, 0.0);
    for (var b in bookings) {
      if (b.status == 'selesai') {
        final month = b.tanggal.month - 1;
        if (month >= 0 && month < 12) revenue[month] += (b.totalHarga / 1000000); // In millions for chart
      }
    }
    return revenue;
  }
}
