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
import 'package:lapangku/models/admin/booking_model.dart';

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
    final bookingsAsync = ref.watch(bookingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildTabs(),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F6FA),
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (bookings) => _buildReportContent(bookings),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan Analistik',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Analisis performa platform dan statistik transaksi.',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final bookingsAsync = ref.read(bookingsProvider);
    final allBookings = bookingsAsync.value ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
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
                label: Text(_selectedDateRange == null 
                  ? 'Pilih Rentang Waktu' 
                  : '${DateFormat('dd MMM yy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yy').format(_selectedDateRange!.end)}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              if (_selectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: () => setState(() => _selectedDateRange = null),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _showExportDialog(allBookings),
                icon: _isExporting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                label: const Text('Ekspor', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1A2E)),
                ),
                Text(
                  '${bookings.length} Data',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
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
                      DataCell(Text(b.namaLapangan.isEmpty ? '-' : b.namaLapangan, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600))),
                      DataCell(Text(b.namaPenyewa.isEmpty ? '-' : b.namaPenyewa, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                      if (isRevenue) DataCell(Text(currencyFormat.format(b.totalHarga), style: const TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 13))),
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
        if (month >= 0 && month < 12) revenue[month] += (b.totalHarga / 1000000); // In millions for chart
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
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan ${_selectedReportType} Lapangku', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              if (_selectedDateRange != null)
                pw.Text('Periode: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: <List<String>>[
                  <String>['Tanggal', 'Lapangan', 'Penyewa', 'Status', 'Total Harga'],
                  ...bookings.map((b) => [
                    DateFormat('dd MMM yyyy').format(b.tanggal),
                    b.namaLapangan,
                    b.namaPenyewa,
                    b.status,
                    'Rp ${b.totalHarga}'
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await _saveAndDownloadFile(bytes, 'Laporan_${_selectedReportType}.pdf', 'application/pdf');
  }

  Future<void> _exportToExcel(List<BookingModel> bookings) async {
    final excelDoc = excel.Excel.createExcel();
    final sheet = excelDoc['Sheet1'];

    sheet.appendRow([
      excel.TextCellValue('Tanggal'),
      excel.TextCellValue('Lapangan'),
      excel.TextCellValue('Penyewa'),
      excel.TextCellValue('Status'),
      excel.TextCellValue('Total Harga'),
    ]);

    for (var b in bookings) {
      sheet.appendRow([
        excel.TextCellValue(DateFormat('dd MMM yyyy').format(b.tanggal)),
        excel.TextCellValue(b.namaLapangan),
        excel.TextCellValue(b.namaPenyewa),
        excel.TextCellValue(b.status),
        excel.IntCellValue(b.totalHarga),
      ]);
    }

    final bytes = excelDoc.encode()!;
    await _saveAndDownloadFile(bytes, 'Laporan_${_selectedReportType}.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  Future<void> _saveAndDownloadFile(List<int> bytes, String filename, String mimeType) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
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
