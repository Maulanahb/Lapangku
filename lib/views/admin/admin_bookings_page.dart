import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/admin/admin_controller.dart';
import 'package:lapangku/models/admin/booking_model.dart';
import 'package:intl/intl.dart';

class AdminBookingsPage extends ConsumerStatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  ConsumerState<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends ConsumerState<AdminBookingsPage> {
  static const _primary = Color(0xFF1B6B3A);
  String _searchQuery = '';
  String _filterStatus = 'semua';

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchFilter(),
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: () async =>
                  ref.read(bookingsProvider.notifier).load(),
              child: bookingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: _primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (bookings) => _buildList(bookings),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kelola Pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            onPressed: () => ref.read(bookingsProvider.notifier).load(),
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
              hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFFADB5BD), size: 20),
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
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
                        color: selected ? _primary : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _chipLabel(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF718096),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Tidak ada pesanan ditemukan',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
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
    final statusColor = _statusColor(booking.status);
    final statusLabel = _statusLabel(booking.status);
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
            color: Colors.black.withOpacity(0.05),
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
                backgroundColor: _primary.withOpacity(0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: _primary,
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
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.namaLapangan,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
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
                    'Rp ${_formatHarga(booking.totalHarga)}'),
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
            Icon(icon, size: 12, color: const Color(0xFF718096)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF718096),
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
              color: Color(0xFF2D3748)),
        ),
      ],
    );
  }

  String _chipLabel(String s) {
    switch (s) {
      case 'semua':
        return 'Semua';
      case 'menunggu':
        return 'Menunggu';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'selesai':
        return Colors.green;
      case 'dikonfirmasi':
        return const Color(0xFF2196F3);
      case 'dibatalkan':
        return Colors.red;
      default:
        return const Color(0xFFFFB74D);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'selesai':
        return 'Selesai';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Menunggu';
    }
  }

  String _formatHarga(int h) {
    if (h >= 1000000) return '${(h / 1000000).toStringAsFixed(1)}jt';
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(0)}rb';
    return h.toString();
  }
}
