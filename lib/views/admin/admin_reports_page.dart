import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:printing/printing.dart';
import 'package:lapangku/standards/constants/app_colors.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  static const _primary = Color(0xFF1B6B3A);
  String _selectedReportType = 'Booking'; // 'Booking' or 'Penghasilan'
  DateTimeRange? _selectedDateRange;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(adminAllBookingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            color: AppColors.backgroundPage,
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (bookings) => _buildReportContent(bookings),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final bookingsAsync = ref.read(adminAllBookingsProvider);
    final allBookings = bookingsAsync.value ?? [];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laporan Analitik',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textHeading,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Analisis performa platform dan statistik transaksi.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => ref.refresh(adminAllBookingsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.hovered) ? AppColors.primary : Colors.grey.shade100),
                  foregroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.hovered) ? Colors.white : AppColors.primary),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Divider
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          // Tabs + actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildTabItem('Laporan Booking', 'Booking'),
                  const SizedBox(width: 12),
                  _buildTabItem('Laporan Penghasilan', 'Penghasilan'),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(
                      _selectedDateRange == null
                          ? 'Pilih Rentang Waktu'
                          : '${DateFormat('dd MMM yy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yy').format(_selectedDateRange!.end)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  if (_selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18),
                        onPressed: () => setState(() => _selectedDateRange = null),
                        splashRadius: 16,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _showExportDialog(allBookings),
                    icon: _isExporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                    label: const Text('Ekspor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
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
    final filteredBookings = _getFilteredBookings(bookings);
    if (_selectedReportType == 'Booking') {
      return _buildBookingReport(filteredBookings);
    } else {
      return _buildRevenueReport(filteredBookings);
    }
  }

  Widget _buildBookingReport(List<BookingModel> bookings) {
    final total = bookings.length;
    final selesai = bookings.where((b) => b.status == 'selesai').length;
    final batal = bookings.where((b) => b.status == 'dibatalkan').length;

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
          _buildChartSection('Tren Booking (Bulanan)', _getMonthlyBookingData(bookings), 'Total Booking', isRevenue: false),
          const SizedBox(height: 24),
          _buildDetailTable(bookings, isRevenue: false),
        ],
      ),
    );
  }

  Widget _buildRevenueReport(List<BookingModel> bookings) {
    final completedBookings = bookings.where((b) => b.status == 'selesai').toList();
    final totalRevenue = completedBookings.fold<int>(0, (sum, b) => sum + b.totalBayar);
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
          _buildChartSection('Tren Penghasilan (Bulanan)', _getMonthlyRevenueData(bookings), 'Penghasilan (dalam Juta)', isRevenue: true),
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
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeading)),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title, List<double> data, String yAxisLabel, {bool isRevenue = false}) {
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isRevenue ? 68 : 40,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) return const SizedBox();
                        String label;
                        if (isRevenue) {
                          // Data dalam Rupiah asli
                          if (value >= 1000000) {
                            final jt = value / 1000000;
                            label = 'Rp ${jt % 1 == 0 ? jt.toInt() : jt.toStringAsFixed(1)} Jt';
                          } else if (value >= 1000) {
                            final rb = value / 1000;
                            label = 'Rp ${rb % 1 == 0 ? rb.toInt() : rb.toStringAsFixed(0)} Rb';
                          } else if (value > 0) {
                            label = 'Rp ${value.toInt()}';
                          } else {
                            label = 'Rp 0';
                          }
                        } else {
                          label = value.toInt().toString();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                        final idx = value.toInt();
                        if (value == value.roundToDouble() && idx >= 0 && idx < 12) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(months[idx], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          );
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRevenue ? 'Rincian Transaksi Selesai' : 'Rincian Booking Terbaru',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textHeading),
                ),
                Text(
                  '${bookings.length} Data',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          if (bookings.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.transparent),
                dividerThickness: 0.5,
                headingRowHeight: 48,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                horizontalMargin: 24,
                columnSpacing: 24,
                columns: [
                  const DataColumn(label: Text('TANGGAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5))),
                  const DataColumn(label: Text('LAPANGAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5))),
                  const DataColumn(label: Text('PENYEWA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5))),
                  if (isRevenue) const DataColumn(label: Text('NOMINAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5))),
                  if (!isRevenue) const DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5))),
                ],
                rows: bookings.take(15).map((b) {
                  return DataRow(
                    cells: [
                      DataCell(Text(dateFormat.format(b.tanggal), style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500))),
                      DataCell(Text(b.fieldName.isEmpty ? '-' : b.fieldName, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600))),
                      DataCell(Text(b.userName.isEmpty ? '-' : b.userName, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                      if (isRevenue) DataCell(Text(currencyFormat.format(b.totalBayar), style: const TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 13))),
                      if (!isRevenue) DataCell(_buildStatusChip(b.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          if (bookings.isEmpty)
             const Padding(
               padding: EdgeInsets.all(40.0),
               child: Center(
                 child: Text('Tidak ada data.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bgColor;
    switch (status.toLowerCase()) {
      case 'selesai': 
        color = const Color(0xFF10B981); 
        bgColor = const Color(0xFFECFDF5);
        break;
      case 'dibatalkan': 
      case 'ditolak':
        color = const Color(0xFFEF4444); 
        bgColor = const Color(0xFFFEF2F2);
        break;
      case 'dikonfirmasi': 
      case 'aktif':
        color = const Color(0xFF3B82F6); 
        bgColor = const Color(0xFFEFF6FF);
        break;
      default: 
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFFFBEB);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
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
        if (month >= 0 && month < 12) revenue[month] += b.totalBayar.toDouble();
      }
    }
    return revenue;
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() => _selectedDateRange = range);
    }
  }

  void _showExportDialog(List<BookingModel> allBookings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ekspor Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Pilih format laporan yang ingin diunduh:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportReport(allBookings, isPdf: true);
            },
            child: const Text('PDF', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              _exportReport(allBookings, isPdf: false);
            },
            child: const Text('Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(List<BookingModel> allBookings, {required bool isPdf}) async {
    setState(() => _isExporting = true);
    try {
      final bookings = _getFilteredBookings(allBookings);
      if (isPdf) {
        await _exportToPdf(bookings);
      } else {
        await _exportToExcel(bookings);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengekspor: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  List<BookingModel> _getFilteredBookings(List<BookingModel> bookings) {
    if (_selectedDateRange == null) return bookings;
    return bookings.where((b) {
      final date = b.tanggal;
      return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _exportToPdf(List<BookingModel> bookings) async {
    final pdf = pw.Document();
    final rangeStr = _selectedDateRange == null 
      ? 'Semua Periode' 
      : '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}';

    int totalKotor = 0;
    int totalPotongan = 0;
    int totalBersih = 0;
    int suksesCount = 0;
    int gagalCount = 0;

    for (var b in bookings) {
      final isSukses = b.status == 'selesai';
      final isGagal = b.status == 'dibatalkan' || b.status == 'expired' || b.status == 'ditolak';

      if (isSukses) {
        totalKotor += b.hargaLapangan;
        totalPotongan += b.biayaLayanan;
        suksesCount++;
      } else if (isGagal) {
        gagalCount++;
      }
    }
    totalBersih = totalKotor - totalPotongan;

    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LAPORAN $_selectedReportType PLATFORM LAPANGKU', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Periode Laporan: $rangeStr', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Tanggal Cetak: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2), // No / Kode Booking
                1: pw.FlexColumnWidth(2.0), // Jadwal Bermain
                2: pw.FlexColumnWidth(1.5), // Pelanggan
                3: pw.FlexColumnWidth(2.2), // Detail Lapangan
                4: pw.FlexColumnWidth(1.8), // Rincian Biaya
                5: pw.FlexColumnWidth(1.3), // Status
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableHeader('No / Kode Booking'),
                    _buildTableHeader('Jadwal Bermain'),
                    _buildTableHeader('Pelanggan'),
                    _buildTableHeader('Detail Lapangan'),
                    _buildTableHeader('Rincian Biaya'),
                    _buildTableHeader('Status'),
                  ],
                ),
                ...List<pw.TableRow>.generate(bookings.length, (index) {
                  final b = bookings[index];
                  return pw.TableRow(
                    children: [
                      _buildTableCell('${index + 1}\n${b.bookingId}'),
                      _buildTableCell('${DateFormat('dd MMM yyyy').format(b.tanggal)} / ${b.timeSlots.join(", ")}'),
                      _buildTableCell(b.userName),
                      _buildTableCell('${b.fieldName} - ${b.fieldCategory}'),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              currencyFormat.format(b.totalBayar),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                            ),
                            pw.Text(
                              b.metodePembayaran,
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: _buildPdfStatusChip(b.status),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RINGKASAN EKSEKUTIF / FOOTER SUMMARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Pendapatan Kotor keseluruhan:', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(currencyFormat.format(totalKotor), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Potongan Aplikasi:', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(currencyFormat.format(totalPotongan), style: pw.TextStyle(color: PdfColors.red, fontSize: 10)),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Pendapatan Bersih Mitra:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(currencyFormat.format(totalBersih), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green, fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Jumlah Transaksi Sukses:', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('$suksesCount Sukses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Jumlah Transaksi Batal/Gagal:', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('$gagalCount Gagal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_$_selectedReportType.pdf',
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  pw.Widget _buildPdfStatusChip(String status) {
    PdfColor textColor;
    PdfColor bgColor;
    switch (status) {
      case 'selesai':
        textColor = PdfColors.green900;
        bgColor = PdfColors.green100;
        break;
      case 'dibatalkan':
      case 'expired':
      case 'ditolak':
        textColor = PdfColors.red900;
        bgColor = PdfColors.red100;
        break;
      case 'dikonfirmasi':
        textColor = PdfColors.blue900;
        bgColor = PdfColors.blue100;
        break;
      default:
        textColor = PdfColors.orange900;
        bgColor = PdfColors.orange100;
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        BookingStatusHelper.getLabel(status).toUpperCase(),
        style: pw.TextStyle(color: textColor, fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  Future<void> _exportToExcel(List<BookingModel> bookings) async {
    final excelDoc = excel.Excel.createExcel();
    final sheet = excelDoc['Sheet1'];

    // Header
    sheet.appendRow([
      excel.TextCellValue('ID Booking / Kode Transaksi (bookingId)'),
      excel.TextCellValue('Tanggal Main (tanggal)'),
      excel.TextCellValue('Waktu / Slot Jam (timeSlots)'),
      excel.TextCellValue('Nama Pelanggan (userName)'),
      excel.TextCellValue('Nama Lapangan (fieldName)'),
      excel.TextCellValue('Kategori Lapangan (fieldCategory)'),
      excel.TextCellValue('Durasi (durasi)'),
      excel.TextCellValue('Harga Lapangan / Pendapatan Kotor (hargaLapangan)'),
      excel.TextCellValue('Biaya Layanan / Komisi Aplikasi (biayaLayanan)'),
      excel.TextCellValue('Total Bayar (totalBayar)'),
      excel.TextCellValue('Metode Pembayaran (metodePembayaran)'),
      excel.TextCellValue('Status (status)'),
      excel.TextCellValue('Tanggal Pemesanan (createdAt)'),
      excel.TextCellValue('Keterangan / Catatan Tambahan'),
    ]);

    int totalKotor = 0;
    int totalPotongan = 0;
    int totalBersih = 0;
    int suksesCount = 0;
    int gagalCount = 0;

    for (var b in bookings) {
      final isSukses = b.status == 'selesai';
      final isGagal = b.status == 'dibatalkan' || b.status == 'expired' || b.status == 'ditolak';

      if (isSukses) {
        totalKotor += b.hargaLapangan;
        totalPotongan += b.biayaLayanan;
        suksesCount++;
      } else if (isGagal) {
        gagalCount++;
      }

      String keterangan = '';
      if (b.status == 'ditolak' && b.alasanPenolakan != null) {
        keterangan = 'Ditolak: ${b.alasanPenolakan}';
      } else if (b.isRescheduleRequested) {
        keterangan = 'Reschedule Requested';
      }

      sheet.appendRow([
        excel.TextCellValue(b.bookingId),
        excel.TextCellValue(DateFormat('yyyy-MM-dd').format(b.tanggal)),
        excel.TextCellValue(b.timeSlots.join(', ')),
        excel.TextCellValue(b.userName),
        excel.TextCellValue(b.fieldName),
        excel.TextCellValue(b.fieldCategory),
        excel.IntCellValue(b.durasi),
        excel.IntCellValue(b.hargaLapangan),
        excel.IntCellValue(b.biayaLayanan),
        excel.IntCellValue(b.totalBayar),
        excel.TextCellValue(b.metodePembayaran),
        excel.TextCellValue(BookingStatusHelper.getLabel(b.status)),
        excel.TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(b.createdAt)),
        excel.TextCellValue(keterangan),
      ]);
    }

    totalBersih = totalKotor - totalPotongan;

    sheet.appendRow([]);
    sheet.appendRow([excel.TextCellValue('RINGKASAN EKSEKUTIF')]);
    sheet.appendRow([excel.TextCellValue('Total Pendapatan Kotor keseluruhan'), excel.IntCellValue(totalKotor)]);
    sheet.appendRow([excel.TextCellValue('Total Potongan Aplikasi'), excel.IntCellValue(totalPotongan)]);
    sheet.appendRow([excel.TextCellValue('Total Pendapatan Bersih Mitra'), excel.IntCellValue(totalBersih)]);
    sheet.appendRow([excel.TextCellValue('Jumlah Transaksi Sukses'), excel.IntCellValue(suksesCount)]);
    sheet.appendRow([excel.TextCellValue('Jumlah Transaksi Batal/Gagal'), excel.IntCellValue(gagalCount)]);

    final bytes = excelDoc.encode()!;
    await _saveAndDownloadFile(bytes, 'Laporan_$_selectedReportType.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  Future<void> _saveAndDownloadFile(List<int> bytes, String filename, String mimeType) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil mengekspor $filename')));
    }
  }
}
