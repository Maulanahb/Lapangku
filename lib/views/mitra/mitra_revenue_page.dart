import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:lapangku/controllers/mitra/mitra_revenue_provider.dart';
import 'package:lapangku/controllers/mitra/mitra_profile_provider.dart';
import 'package:lapangku/models/mitra/mitra_revenue_model.dart';
import 'package:lapangku/models/mitra/mitra_payout_model.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';
import 'package:lapangku/views/mitra/mitra_payout_request_sheet.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/core/services/firestore_service.dart';

class MitraRevenuePage extends ConsumerStatefulWidget {
  const MitraRevenuePage({super.key});

  @override
  ConsumerState<MitraRevenuePage> createState() => _MitraRevenuePageState();
}

class _MitraRevenuePageState extends ConsumerState<MitraRevenuePage> {
  String _selectedFilter = 'Hari Ini';
  bool _isExporting = false;

  Future<void> _pickDateRange() async {
    final currentRange = ref.read(revenueDateRangeProvider);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: currentRange.start, end: currentRange.end),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _selectedFilter = 'Kustom';
      });
      ref.read(revenueDateRangeProvider.notifier).state = DateRange(range.start, range.end);
    }
  }

  Future<List<BookingModel>> _fetchMitraBookings(String mitraId) async {
    final dateRange = ref.read(revenueDateRangeProvider);
    
    final snap = await FirestoreService.instance
        .collection('bookings')
        .where('mitraId', isEqualTo: mitraId)
        .get();
        
    final allBookings = snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
    
    final filteredBookings = allBookings.where((b) {
      final date = b.tanggal;
      return date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
             date.isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();
    
    filteredBookings.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return filteredBookings;
  }

  void _showExportDialog(String mitraId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ekspor Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Pilih format laporan yang ingin diunduh untuk Mitra LapangKu:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportReport(mitraId, isPdf: true);
            },
            child: const Text('PDF', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _exportReport(mitraId, isPdf: false);
            },
            child: const Text('Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(String mitraId, {required bool isPdf}) async {
    setState(() => _isExporting = true);
    try {
      final bookings = await _fetchMitraBookings(mitraId);
      if (bookings.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data transaksi untuk diekspor pada periode ini.')),
          );
        }
        return;
      }
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

  Future<void> _exportToPdf(List<BookingModel> bookings) async {
    final pdf = pw.Document();
    final dateRange = ref.read(revenueDateRangeProvider);
    final rangeStr = '${DateFormat('dd MMM yyyy').format(dateRange.start)} - ${DateFormat('dd MMM yyyy').format(dateRange.end)}';

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
                    pw.Text('LAPORAN FINANSIAL & OPERASIONAL MITRA LAPANGKU', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
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
      name: 'Laporan_Finansial_Mitra.pdf',
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
      if (b.status == 'ditolak') {
        keterangan = 'Ditolak';
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
    await _saveAndDownloadFile(
      bytes,
      'Laporan_Finansial_Mitra.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
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

  @override
  Widget build(BuildContext context) {
    // Listen to date range changes to trigger loadRevenue smoothly
    ref.listen<DateRange>(revenueDateRangeProvider, (previous, next) {
      ref.read(mitraRevenueProvider.notifier).loadRevenue(next);
    });

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
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _isExporting
                ? null
                : () {
                    final profileAsync = ref.read(mitraProfileProvider);
                    if (profileAsync.hasValue) {
                      _showExportDialog(profileAsync.value!.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal mengambil profil mitra.')),
                      );
                    }
                  },
          ),
        ],
      ),
      body: revenueAsync.hasValue
          ? Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => ref.read(mitraRevenueProvider.notifier).loadRevenue(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDescriptionText(),
                        _buildHeroCard(revenueAsync.value!),
                        _buildFilterChips(),
                        _buildSectionTitle("Ringkasan"),
                        _buildSummaryGrid(revenueAsync.value!),
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
                        _buildTransactionList(revenueAsync.value!.transactions),
                        _buildPayoutStatus(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                if (revenueAsync.isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      color: AppColors.primary,
                      minHeight: 3,
                    ),
                  ),
              ],
            )
          : revenueAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Gagal memuat data',
                subtitle: err.toString(),
              ),
              data: (_) => const SizedBox.shrink(),
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
                "Saldo Aktif",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      revenue.revenueGrowth >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${revenue.revenueGrowth >= 0 ? '+' : ''}${revenue.revenueGrowth.toStringAsFixed(0)}%",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox( // FIX: Gunakan FittedBox agar nominal tidak overflow
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(revenue.availableBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final profileAsync = ref.read(mitraProfileProvider);
                if (profileAsync.hasValue) {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => MitraPayoutRequestSheet(
                      availableBalance: revenue.availableBalance,
                      profile: profileAsync.value!,
                    ),
                  );
                  if (result == true) {
                    ref.read(mitraRevenueProvider.notifier).loadRevenue();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tarik Dana', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
                  revenue.totalOrders > 0 ? (revenue.periodRevenue ~/ revenue.totalOrders) : 0,
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
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
              final now = DateTime.now();
              DateRange range;
              if (filter == 'Hari Ini') {
                range = DateRange(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
              } else if (filter == 'Minggu Ini') {
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                range = DateRange(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day), DateTime(now.year, now.month, now.day, 23, 59, 59));
              } else if (filter == 'Bulan Ini') {
                range = DateRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0, 23, 59, 59));
              } else { // Tahun Ini
                range = DateRange(DateTime(now.year, 1, 1), DateTime(now.year, 12, 31, 23, 59, 59));
              }
              ref.read(revenueDateRangeProvider.notifier).state = range;
            },
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
            "Total Pendapatan",
            CurrencyFormatter.format(revenue.totalRevenue),
            "Sepanjang waktu",
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
    final profileAsync = ref.watch(mitraProfileProvider);
    if (!profileAsync.hasValue) return const SizedBox.shrink();

    final mitraId = profileAsync.value!.id;
    final service = MitraService();

    return StreamBuilder<List<MitraPayoutModel>>(
      stream: service.streamMitraPayouts(mitraId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final payouts = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                "Riwayat Penarikan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: payouts.length > 5 ? 5 : payouts.length,
              itemBuilder: (context, index) {
                final payout = payouts[index];
                
                Color statusColor;
                IconData statusIcon;
                String statusText;

                switch (payout.status) {
                  case 'completed':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusText = 'Selesai';
                    break;
                  case 'rejected':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    statusText = 'Ditolak';
                    break;
                  default:
                    statusColor = Colors.orange;
                    statusIcon = Icons.access_time;
                    statusText = 'Diproses';
                }

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
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tarik Dana",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy - HH:mm').format(payout.requestedAt),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(payout.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
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
