import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/admin/booking_model.dart';
import 'package:lapangku/shared/constants/app_colors.dart';
import 'package:lapangku/shared/utils/currency_formatter.dart';
import 'package:lapangku/shared/models/booking_status.dart';
import 'package:lapangku/shared/widgets/empty_state_widget.dart';
import 'package:intl/intl.dart';

class AdminBookingsPage extends ConsumerStatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  ConsumerState<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends ConsumerState<AdminBookingsPage> {
  String _searchQuery = '';
  String _filterStatus = 'semua';

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Column(
      children: [
        _buildHeader(),
        _buildSearchFilter(),
        Expanded(
          child: Container(
            color: AppColors.backgroundInput,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async =>
                  ref.read(bookingsProvider.notifier).load(),
              child: bookingsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (bookings) => _buildList(bookings),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Pesanan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textHeading,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pantau seluruh transaksi dan status booking.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: () => ref.read(bookingsProvider.notifier).load(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari pesanan...',
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
              children: ['semua', 'menunggu', 'dikonfirmasi', 'selesai', 'dibatalkan']
                  .map((status) {
                final selected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterStatus = status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.backgroundInput,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _chipLabel(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
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

  Widget _buildList(List<BookingModel> bookings) {
    var filtered = bookings.where((b) {
      final matchSearch = b.namaPenyewa.toLowerCase().contains(_searchQuery) ||
          b.namaLapangan.toLowerCase().contains(_searchQuery);
      final matchStatus =
          _filterStatus == 'semua' || b.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();

    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'Tidak ada pesanan ditemukan',
        iconSize: 64,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildBookingCard(filtered[i]),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final status = BookingStatusParsing.fromString(booking.status);
    final initials = booking.namaPenyewa.trim().isNotEmpty
        ? booking.namaPenyewa
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    final dateStr = DateFormat('dd MMM yyyy', 'id').format(booking.tanggal);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.namaPenyewa,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textHeading),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.namaLapangan,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Status badge — pakai BookingStatus.color & .chipLabel
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.chipLabel,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Details
          Row(
            children: [
              Expanded(
                child: _detailItem(
                    Icons.calendar_today_outlined, 'Tanggal', dateStr),
              ),
              Expanded(
                child: _detailItem(Icons.access_time_outlined, 'Waktu',
                    '${booking.jamMulai} - ${booking.jamSelesai}'),
              ),
              Expanded(
                child: _detailItem(Icons.payments_outlined, 'Total',
                    CurrencyFormatter.format(booking.totalHarga)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark),
        ),
      ],
    );
  }

  /// Label untuk chip filter — gunakan BookingStatus jika bukan 'semua'
  String _chipLabel(String s) {
    if (s == 'semua') return 'Semua';
    return BookingStatusParsing.fromString(s).chipLabel;
  }
}
