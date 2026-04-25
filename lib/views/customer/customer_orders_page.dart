import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';

class CustomerOrdersPage extends ConsumerStatefulWidget {
  const CustomerOrdersPage({super.key});
  @override
  ConsumerState<CustomerOrdersPage> createState() => _State();
}

class _State extends ConsumerState<CustomerOrdersPage> {
  String _filter = 'Semua';
  final List<String> _filters = ['Semua', 'Aktif', 'Menunggu', 'Selesai', 'Dibatalkan'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return _loginPrompt();

    final bookingsAsync = ref.watch(userBookingsProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B6B3A),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.invalidate(userBookingsProvider(user.uid)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
              error: (e, _) => Center(child: Text('Gagal memuat pesanan:\n$e', textAlign: TextAlign.center)),
              data: (bookings) => _buildBookingList(bookings, user.uid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginPrompt() => const Scaffold(
    backgroundColor: Color(0xFFF4F6F9),
    body: Center(child: Text('Silakan login untuk melihat pesanan', style: TextStyle(color: Color(0xFF718096)))),
  );

  Widget _buildFilterChips() {
    return Container(
      height: 56,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final sel = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF1B6B3A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? const Color(0xFF1B6B3A) : Colors.grey.shade300),
                ),
                child: Text(f, style: TextStyle(
                  fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                  color: sel ? Colors.white : const Color(0xFF718096),
                )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Map<String, dynamic>> bookings, String userId) {
    // Filter berdasarkan status
    final filtered = _filter == 'Semua'
        ? bookings
        : bookings.where((b) {
            final status = (b['status'] ?? '').toString().toLowerCase();
            final filterKey = _filter.toLowerCase();
            if (filterKey == 'aktif') return status == 'dikonfirmasi';
            return status == filterKey;
          }).toList();

    if (filtered.isEmpty) return _buildEmpty();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _BookingCard(
        booking: filtered[i],
        onCancel: () => _cancelBooking(filtered[i]['id'], userId),
        onRefresh: () => ref.invalidate(userBookingsProvider(userId)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('Belum ada pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        const SizedBox(height: 8),
        Text(
          _filter == 'Semua' ? 'Pesanan Anda akan muncul di sini' : 'Tidak ada pesanan dengan status "$_filter"',
          style: const TextStyle(color: Color(0xFF718096)),
        ),
      ]),
    );
  }

  Future<void> _cancelBooking(String bookingId, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final service = ref.read(bookingServiceProvider);
      await service.cancelBooking(bookingId);
      ref.invalidate(userBookingsProvider(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pesanan berhasil dibatalkan'),
          backgroundColor: Color(0xFF1B6B3A),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

// ── BOOKING CARD ──
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;

  const _BookingCard({required this.booking, required this.onCancel, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] ?? 'menunggu').toString();
    final nama = booking['namaLapangan'] ?? 'Lapangan';
    final jamMulai = booking['jamMulai'] ?? '';
    final jamSelesai = booking['jamSelesai'] ?? '';
    final harga = (booking['totalHarga'] ?? 0) as int;
    final tanggal = (booking['tanggal'] as Timestamp?)?.toDate();
    final id = booking['id'] ?? '';

    final statusInfo = _getStatusInfo(status);
    final dateStr = tanggal != null ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tanggal) : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID + Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ID #${id.substring(0, id.length > 8 ? 8 : id.length).toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF718096), fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusInfo['label'] as String,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusInfo['textColor'] as Color)),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder image
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: const Color(0xFFE8F5EC), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Icon(Icons.sports_soccer, size: 28, color: Color(0xFF1B6B3A))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nama, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF718096)),
                      const SizedBox(width: 4),
                      Expanded(child: Text('$dateStr · $jamMulai', style: const TextStyle(fontSize: 12, color: Color(0xFF718096)))),
                    ]),
                  ]),
                ),
              ],
            ),
          ),
          // Footer: Harga + Actions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('TOTAL BAYAR', style: TextStyle(fontSize: 9, color: Color(0xFF718096), letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(harga),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
                ]),
                const Spacer(),
                // Action buttons based on status
                ..._buildActions(context, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return [
          _actionBtn(Icons.upload_file, 'Upload Bukti', const Color(0xFF1B6B3A), () {}),
          const SizedBox(width: 8),
          _actionBtn(Icons.close, 'Batalkan', Colors.red.shade400, onCancel),
        ];
      case 'dikonfirmasi':
        return [
          _actionBtn(Icons.confirmation_num_outlined, 'Lihat Tiket', const Color(0xFF1B6B3A), () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur tiket segera hadir!'), backgroundColor: Color(0xFF1B6B3A)));
          }),
        ];
      case 'selesai':
        return [
          _actionBtn(Icons.star_outline, 'Beri Ulasan', Colors.amber.shade700, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ulasan segera hadir!'), backgroundColor: Color(0xFF1B6B3A)));
          }),
        ];
      default:
        return [];
    }
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'dikonfirmasi':
        return {'label': 'AKTIF', 'bgColor': const Color(0xFFD1FAE5), 'textColor': const Color(0xFF1B6B3A)};
      case 'menunggu':
        return {'label': 'MENUNGGU KONFIRMASI', 'bgColor': const Color(0xFFFEF3C7), 'textColor': Colors.orange.shade800};
      case 'selesai':
        return {'label': 'SELESAI', 'bgColor': const Color(0xFFE0E7FF), 'textColor': Colors.indigo};
      case 'dibatalkan':
        return {'label': 'DIBATALKAN', 'bgColor': const Color(0xFFFEE2E2), 'textColor': Colors.red.shade700};
      default:
        return {'label': status.toUpperCase(), 'bgColor': Colors.grey.shade100, 'textColor': Colors.grey};
    }
  }
}
