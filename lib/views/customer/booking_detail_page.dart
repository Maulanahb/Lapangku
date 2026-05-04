import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:lapangku/views/customer/payment_upload_page.dart';

class BookingDetailPage extends ConsumerWidget {
  final String bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingStream = ref.watch(activeBookingStreamProvider(bookingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Booking Detail', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A), fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B6B3A)),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: bookingStream.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B6B3A))),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (booking) {
          if (booking == null) return const Center(child: Text('Booking tidak ditemukan'));
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(booking),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFieldInfoCard(booking),
                      const SizedBox(height: 16),
                      _buildStatusTimeline(booking),
                      const SizedBox(height: 16),
                      _buildPaymentInfo(booking),
                      const SizedBox(height: 24),
                      _buildActionButtons(context, ref, booking),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BookingModel booking) {
    String title;
    Color bgColor;

    switch (booking.status) {
      case 'menunggu_bayar':
        title = 'Menunggu Pembayaran';
        bgColor = Colors.orange.shade800;
        break;
      case 'menunggu_konfirmasi':
        title = 'Menunggu Konfirmasi Pembayaran';
        bgColor = const Color(0xFF1A365D);
        break;
      case 'dikonfirmasi':
      case 'aktif':
        title = 'Pesanan Dikonfirmasi';
        bgColor = const Color(0xFF1B6B3A);
        break;
      case 'selesai':
        title = 'Pesanan Selesai';
        bgColor = Colors.grey.shade700;
        break;
      case 'dibatalkan':
        title = 'Pesanan Dibatalkan';
        bgColor = Colors.red.shade700;
        break;
      default:
        title = 'Status Tidak Diketahui';
        bgColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('#${booking.bookingId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFieldInfoCard(BookingModel booking) {
    final dateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.length > 1 
        ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]}'
        : booking.timeSlots.first;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: booking.fieldImageUrl.isNotEmpty
                ? Image.network(booking.fieldImageUrl, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _phImage())
                : _phImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.fieldName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF718096)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(booking.fieldAddress, style: const TextStyle(fontSize: 12, color: Color(0xFF718096)))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF1B6B3A), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jadwal Main', style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
                          Text('$dateStr â€¢ $timeStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3748))),
                        ],
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

  Widget _phImage() => Container(height: 140, color: const Color(0xFFE8F5EC), child: const Center(child: Icon(Icons.sports_soccer, size: 48, color: Color(0xFF1B6B3A))));

  Widget _buildStatusTimeline(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildTimelineItem('Pesanan Dibuat', booking, 'menunggu_bayar', true),
          _buildTimelineItem('Pembayaran Dikonfirmasi', booking, 'dikonfirmasi', booking.status != 'menunggu_bayar' && booking.status != 'menunggu_konfirmasi'),
          _buildTimelineItem('Pesanan Aktif', booking, 'aktif', booking.status == 'dikonfirmasi' || booking.status == 'aktif' || booking.status == 'selesai', isLast: false, badge: 'AKTIF'),
          _buildTimelineItem('Selesai', booking, 'selesai', booking.status == 'selesai', isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, BookingModel booking, String targetStatus, bool isCompleted, {bool isLast = false, String? badge}) {
    // Find time from timeline
    String timeStr = '';
    if (isCompleted) {
      try {
        final entry = booking.statusTimeline.firstWhere(
          (e) => e['status'] == targetStatus || 
                (targetStatus == 'menunggu_bayar' && e['status'] == 'menunggu_bayar') ||
                (targetStatus == 'dikonfirmasi' && e['status'] == 'dikonfirmasi'),
          orElse: () => {'waktu': null},
        );
        if (entry['waktu'] != null) {
          final dt = (entry['waktu'] as dynamic).toDate() as DateTime;
          timeStr = DateFormat('HH:mm').format(dt);
        }
      } catch (_) {}
    }

    if (badge == 'AKTIF' && booking.status == 'dikonfirmasi') timeStr = 'Sekarang';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFF1B6B3A) : const Color(0xFFE2E8F0),
              ),
              child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(width: 2, height: 30, color: isCompleted ? const Color(0xFF1B6B3A) : const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal, color: isCompleted ? const Color(0xFF2D3748) : const Color(0xFF718096))),
                    if (badge != null && booking.status == 'dikonfirmasi') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                        child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                      ),
                    ]
                  ],
                ),
                if (timeStr.isNotEmpty)
                  Text(timeStr, style: TextStyle(fontSize: 12, color: badge != null && booking.status == 'dikonfirmasi' ? const Color(0xFF1B6B3A) : const Color(0xFF718096))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Info Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Metode', style: TextStyle(color: Color(0xFF718096))),
              Text(booking.metodePembayaran.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(color: Color(0xFF718096))),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(booking.totalBayar),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B6B3A)),
              ),
            ],
          ),
          if (booking.buktiTransferUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: NetworkImage(booking.buktiTransferUrl!), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Bukti Transfer', style: TextStyle(fontWeight: FontWeight.w500))),
                  const Text('Lihat Bukti', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A), fontSize: 12)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, BookingModel booking) {
    return Column(
      children: [
        if (booking.status == 'menunggu_bayar') ...[
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentUploadPage(booking: booking)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6B3A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
        ],
        if (booking.status == 'dikonfirmasi' || booking.status == 'aktif') ...[
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur tiket segera hadir!'), backgroundColor: Color(0xFF1B6B3A)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6B3A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Lihat Tiket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.phone_outlined),
          label: const Text('Hubungi Pemilik Lapangan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1B6B3A),
            side: const BorderSide(color: Color(0xFF1B6B3A)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (booking.status == 'menunggu_bayar' || booking.status == 'menunggu_konfirmasi') ...[
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _cancelBooking(context, ref, booking.id),
            child: Text('Batalkan Pesanan', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final service = ref.read(bookingServiceProvider);
      await service.cancelBooking(bookingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan dibatalkan'), backgroundColor: Color(0xFF1B6B3A)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
