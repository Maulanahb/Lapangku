import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:intl/intl.dart';

class AdminBookingsPage extends ConsumerStatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  ConsumerState<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends ConsumerState<AdminBookingsPage> {
  static const _primary = Color(0xFF1B6B3A);
  static const _pageSize = 10;

  String _searchQuery = '';
  String _filterStatus = 'semua';
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(adminAllBookingsProvider);

    return Column(
      children: [
        _buildHeader(),
        _buildSearchFilter(bookingsAsync),
        Expanded(
          child: Container(
            color: AppColors.backgroundPage,
            child: RefreshIndicator(
              color: _primary,
              onRefresh: () async => ref.refresh(adminAllBookingsProvider),
              child: bookingsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: _primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (bookings) => _buildContent(bookings),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Pesanan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textHeading,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pantau seluruh transaksi dan status booking secara realtime.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => ref.refresh(adminAllBookingsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.hovered)
                      ? _primary
                      : Colors.grey.shade100),
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.hovered)
                      ? Colors.white
                      : _primary),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20))),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  // --- Search + Filter ---
  Widget _buildSearchFilter(AsyncValue<List<BookingModel>> bookingsAsync) {
    final filters = [
      {'value': 'semua', 'label': 'Semua'},
      {'value': 'menunggu_bayar', 'label': 'Menunggu Bayar'},
      {'value': 'dikonfirmasi', 'label': 'Dikonfirmasi'},
      {'value': 'selesai', 'label': 'Selesai'},
      {'value': 'dibatalkan', 'label': 'Dibatalkan'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() {
              _searchQuery = v.toLowerCase();
              _currentPage = 0;
            }),
            decoration: InputDecoration(
              hintText: 'Cari ID pesanan, pelanggan, atau lapangan...',
              hintStyle: const TextStyle(color: AppColors.hint, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.hint, size: 20),
              filled: true,
              fillColor: AppColors.backgroundInput,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final val = f['value']!;
                final label = f['label']!;
                final isSelected = _filterStatus == val;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _filterStatus = val;
                      _currentPage = 0;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? _primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Content ---
  Widget _buildContent(List<BookingModel> bookings) {
    // Filter by status group
    var filtered = bookings.where((b) {
      final matchSearch = _searchQuery.isEmpty ||
          b.userName.toLowerCase().contains(_searchQuery) ||
          b.fieldName.toLowerCase().contains(_searchQuery) ||
          b.bookingId.toLowerCase().contains(_searchQuery);

      bool matchStatus;
      if (_filterStatus == 'semua') {
        matchStatus = true;
      } else if (_filterStatus == 'menunggu_bayar') {
        matchStatus = b.status == BookingStatusHelper.menungguBayar;
      } else if (_filterStatus == 'dibatalkan') {
        matchStatus = b.status == BookingStatusHelper.dibatalkan ||
            b.status == BookingStatusHelper.ditolak ||
            b.status == BookingStatusHelper.expired;
      } else {
        matchStatus = b.status == _filterStatus;
      }

      return matchSearch && matchStatus;
    }).toList();

    // Sort by createdAt descending
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'Tidak ada pesanan ditemukan',
        iconSize: 64,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // The table card
          _buildTableCard(filtered),
        ],
      ),
    );
  }

  // --- Table Card ---
  Widget _buildTableCard(List<BookingModel> bookings) {
    final totalPages = bookings.isEmpty
        ? 1
        : ((bookings.length - 1) ~/ _pageSize) + 1;
    final currentPage =
        _currentPage >= totalPages ? totalPages - 1 : _currentPage;
    final startIndex = currentPage * _pageSize;
    final endIndex = startIndex + _pageSize > bookings.length
        ? bookings.length
        : startIndex + _pageSize;
    final pageItems = bookings.sublist(startIndex, endIndex);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Tabel Pesanan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textHeading)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${bookings.length} pesanan',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Diperbarui realtime',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // Scrollable DataTable
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth:
                        constraints.maxWidth < 900 ? 900 : constraints.maxWidth,
                  ),
                  child: DataTable(
                    horizontalMargin: 24,
                    columnSpacing: 20,
                    dataRowMinHeight: 58,
                    dataRowMaxHeight: 70,
                    headingRowHeight: 44,
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF8F9FA)),
                    dividerThickness: 0.8,
                    columns: const [
                      DataColumn(
                          label: Text('ID PESANAN',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3))),
                      DataColumn(
                          label: Text('PELANGGAN',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3))),
                      DataColumn(
                          label: Text('LAPANGAN',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3))),
                      DataColumn(
                          label: Text('TANGGAL',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3))),
                      DataColumn(
                          label: Text('JAM MAIN',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3))),
                      DataColumn(
                          label: Text('TOTAL',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3)),
                          numeric: true),
                      DataColumn(
                          label: Text('METODE',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3))),
                      DataColumn(
                          label: Text('STATUS',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3))),
                    ],
                rows: pageItems.map((b) => _buildDataRow(b)).toList(),
              ),
            ),
          );
        },
      ),
          if (bookings.length > _pageSize)
            _buildPaginationFooter(
              currentPage: currentPage,
              totalPages: totalPages,
              totalItems: bookings.length,
              startItem: startIndex + 1,
              endItem: endIndex,
              onPrevious: currentPage == 0
                  ? null
                  : () => setState(() => _currentPage = currentPage - 1),
              onNext: currentPage >= totalPages - 1
                  ? null
                  : () => setState(() => _currentPage = currentPage + 1),
            ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter({
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required int startItem,
    required int endItem,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Text(
            'Menampilkan $startItem-$endItem dari $totalItems pesanan',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: onPrevious,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              disabledForegroundColor: Colors.grey.shade400,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text('Sebelumnya'),
          ),
          const SizedBox(width: 10),
          Text(
            '${currentPage + 1} / $totalPages',
            style: const TextStyle(
              color: AppColors.textHeading,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onNext,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              disabledForegroundColor: Colors.grey.shade400,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text('Berikutnya'),
          ),
        ],
      ),
    );
  }

  // --- Data Row ---
  DataRow _buildDataRow(BookingModel booking) {
    final statusColor = _statusColor(booking.status);
    final statusLabel = BookingStatusHelper.getLabel(booking.status);
    final dateStr = DateFormat('dd MMM yyyy', 'id').format(booking.tanggal);
    final customerName = booking.userName.trim().isNotEmpty
        ? booking.userName.trim()
        : 'Tanpa nama';
    final fieldName = booking.fieldName.trim().isNotEmpty
        ? booking.fieldName.trim()
        : 'Belum tersedia';
    final timeStr = booking.timeSlots.isNotEmpty
        ? booking.timeSlots.first.split(' - ').first
        : '-';
    final timeEnd = booking.timeSlots.isNotEmpty
        ? booking.timeSlots.last.split(' - ').last
        : '';
    final jamStr = timeEnd.isNotEmpty ? '$timeStr – $timeEnd' : timeStr;

    final initials = customerName != 'Tanpa nama'
        ? customerName.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    String metode = booking.metodePembayaran;
    if (metode.isEmpty) metode = '-';
    metode = metode.length > 12 ? '${metode.substring(0, 12)}…' : metode;

    return DataRow(
      cells: [
        // ID Pesanan
        DataCell(
          GestureDetector(
            onTap: () => _showBookingDetail(booking),
            child: Text(
              booking.bookingId,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _primary,
                decoration: TextDecoration.underline,
                decorationColor: _primary,
              ),
            ),
          ),
        ),

        // Pelanggan
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _primary.withOpacity(0.1),
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 10,
                      color: _primary,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(
                customerName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        )),

        // Lapangan
        DataCell(SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fieldName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textDark),
                overflow: TextOverflow.ellipsis,
              ),
              if (booking.fieldCategory.isNotEmpty)
                Text(
                  booking.fieldCategory,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        )),

        // Tanggal
        DataCell(Text(
          dateStr,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        )),

        // Jam Main
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(jamStr,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text(booking.durasi > 0 ? '${booking.durasi} jam' : '-',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        )),

        // Total
        DataCell(Text(
          booking.totalBayar > 0
              ? CurrencyFormatter.format(booking.totalBayar)
              : '-',
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: _primary),
          textAlign: TextAlign.right,
        )),

        // Metode
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            metode,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600),
          ),
        )),

        // Status
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
                color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        )),
      ],
    );
  }

  // --- Detail Dialog ---
  void _showBookingDetail(BookingModel booking) {
    final statusColor = _statusColor(booking.status);
    final dateStr =
        DateFormat('EEEE, dd MMMM yyyy', 'id').format(booking.tanggal);
    final createdStr =
        DateFormat('dd MMM yyyy, HH:mm', 'id').format(booking.createdAt);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 560,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.bookingId,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16),
                          ),
                          Text(
                            'Dibuat: $createdStr',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        BookingStatusHelper.getLabel(booking.status),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15)),
                    ),
                  ],
                ),
              ),

              // Dialog Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _detailSection('Informasi Pelanggan', [
                        _detailRow(
                            Icons.person_outline, 'Nama', booking.userName),
                        _detailRow(Icons.fingerprint_outlined, 'User ID',
                            booking.userId),
                      ]),
                      const SizedBox(height: 16),
                      _detailSection('Informasi Lapangan', [
                        _detailRow(Icons.stadium_outlined, 'Lapangan',
                            booking.fieldName),
                        _detailRow(
                            Icons.category_outlined,
                            'Kategori',
                            booking.fieldCategory.isEmpty
                                ? '-'
                                : booking.fieldCategory),
                        _detailRow(
                            Icons.location_on_outlined,
                            'Alamat',
                            booking.fieldAddress.isEmpty
                                ? '-'
                                : booking.fieldAddress),
                      ]),
                      const SizedBox(height: 16),
                      _detailSection('Jadwal Booking', [
                        _detailRow(
                            Icons.calendar_today_outlined, 'Tanggal', dateStr),
                        _detailRow(
                            Icons.access_time_outlined,
                            'Slot Waktu',
                            booking.timeSlots.isNotEmpty
                                ? booking.timeSlots.join(', ')
                                : '-'),
                        _detailRow(Icons.timelapse_outlined, 'Durasi',
                            '${booking.durasi} Jam'),
                      ]),
                      const SizedBox(height: 16),
                      _detailSection('Pembayaran', [
                        _detailRow(Icons.payments_outlined, 'Harga Lapangan',
                            CurrencyFormatter.format(booking.hargaLapangan)),
                        _detailRow(Icons.percent_outlined, 'Biaya Layanan',
                            CurrencyFormatter.format(booking.biayaLayanan)),
                        _detailRow(
                          Icons.monetization_on_outlined,
                          'Total Bayar',
                          CurrencyFormatter.format(booking.totalBayar),
                          highlight: true,
                        ),
                        _detailRow(
                            Icons.credit_card_outlined,
                            'Metode Bayar',
                            booking.metodePembayaran.isEmpty
                                ? '-'
                                : booking.metodePembayaran),
                      ]),
                      const SizedBox(height: 16),
                      _detailSection('Status', [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: statusColor),
                            const SizedBox(width: 10),
                            const Text('Status',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                BookingStatusHelper.getLabel(booking.status),
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16, color: highlight ? _primary : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: highlight ? _primary : AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: highlight ? _primary : AppColors.textDark,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Color _statusColor(String status) {
    switch (status) {
      case BookingStatusHelper.menungguBayar:
        return const Color(0xFFFF9800);
      case BookingStatusHelper.dikonfirmasi:
        return const Color(0xFF4285F4);
      case BookingStatusHelper.selesai:
        return const Color(0xFF1B6B3A);
      case BookingStatusHelper.dibatalkan:
      case BookingStatusHelper.ditolak:
      case BookingStatusHelper.expired:
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }
}
