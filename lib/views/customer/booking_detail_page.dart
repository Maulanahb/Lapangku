import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:lapangku/views/customer/payment_upload_page.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/models/booking_status.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';

class BookingDetailPage extends ConsumerWidget {
  final String bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingStream = ref.watch(activeBookingStreamProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text('Booking Detail',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {})],
      ),
      body: bookingStream.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (booking) {
          if (booking == null) return const Center(child: Text('Booking tidak ditemukan'));
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(booking),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _buildFieldInfoCard(booking),
                    if (booking.status == BookingStatusHelper.dikonfirmasi) ...[
                      const SizedBox(height: 16),
                      _buildETicketCard(booking),
                    ],
                    const SizedBox(height: 16),
                    _buildStatusTimeline(booking),
                    const SizedBox(height: 16),
                    _buildPaymentInfo(context, booking),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, ref, booking),
                    const SizedBox(height: 40),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BookingModel booking) {
    final status = BookingStatusParsing.fromString(booking.status);
    return Container(
      width: double.infinity,
      color: status.headerColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(status.headerTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text('#${booking.bookingId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildFieldInfoCard(BookingModel booking) {
    final dateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.length > 1
        ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]}'
        : booking.timeSlots.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: booking.fieldImageUrl.isNotEmpty
              ? Image.network(booking.fieldImageUrl, height: 140, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImage())
              : _placeholderImage(),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.fieldName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(booking.fieldAddress,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.backgroundPage, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Jadwal Main', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('$dateStr • $timeStr',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                ]),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _placeholderImage() => Container(
      height: 140,
      color: AppColors.primaryLight,
      child: const Center(child: Icon(Icons.stadium_outlined, size: 48, color: AppColors.primary)));

  Widget _buildStatusTimeline(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        _buildTimelineItem('Pesanan Dibuat', booking, 'menunggu_bayar', true),
        _buildTimelineItem('Pembayaran Dikonfirmasi', booking, 'dikonfirmasi',
            booking.status != 'menunggu_bayar' && booking.status != 'menunggu_konfirmasi'),
        _buildTimelineItem('Pesanan Aktif', booking, 'aktif',
            booking.status == 'dikonfirmasi' || booking.status == 'aktif' || booking.status == 'selesai',
            isLast: false, badge: 'AKTIF'),
        _buildTimelineItem('Selesai', booking, 'selesai', booking.status == 'selesai', isLast: true),
      ]),
    );
  }

  Widget _buildTimelineItem(String title, BookingModel booking, String targetStatus, bool isCompleted,
      {bool isLast = false, String? badge}) {
    String timeStr = '';
    if (isCompleted) {
      try {
        final entry = booking.statusTimeline.firstWhere(
          (e) => e['status'] == targetStatus,
          orElse: () => {'waktu': null},
        );
        if (entry['waktu'] != null) {
          final dt = (entry['waktu'] as dynamic).toDate() as DateTime;
          timeStr = DateFormat('HH:mm').format(dt);
        }
      } catch (_) {}
    }
    if (badge == 'AKTIF' && booking.status == 'dikonfirmasi') timeStr = 'Sekarang';
    final isActiveBadge = badge != null && booking.status == 'dikonfirmasi';

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : AppColors.divider,
          ),
          child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
        ),
        if (!isLast) Container(width: 2, height: 30, color: isCompleted ? AppColors.primary : AppColors.divider),
      ]),
      const SizedBox(width: 16),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? AppColors.textDark : AppColors.textSecondary)),
              if (isActiveBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.statusPendingBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                ),
              ],
            ]),
            if (timeStr.isNotEmpty)
              Text(timeStr, style: TextStyle(fontSize: 12, color: isActiveBadge ? AppColors.primary : AppColors.textSecondary)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildPaymentInfo(BuildContext context, BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Info Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Metode', style: TextStyle(color: AppColors.textSecondary)),
          Text(booking.metodePembayaran.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(color: AppColors.textSecondary)),
          Text(CurrencyFormatter.format(booking.totalBayar),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
        ]),
        if (booking.buktiTransferUrl != null) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showBuktiTransferDialog(context, booking.buktiTransferUrl!),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.backgroundPage, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(image: NetworkImage(booking.buktiTransferUrl!), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Bukti Transfer', style: TextStyle(fontWeight: FontWeight.w500))),
                const Text('Lihat Bukti', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildETicketCard(BookingModel booking) {
    final dateStr = DateFormat('EEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.length > 1
        ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]}'
        : booking.timeSlots.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // ── Header: E-Ticket + LUNAS badge ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.confirmation_number, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-Ticket Anda',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      Text('Tunjukkan ke petugas lapangan',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF0F5A3C), size: 14),
                      SizedBox(width: 4),
                      Text('LUNAS',
                          style: TextStyle(
                              color: Color(0xFF0F5A3C), fontWeight: FontWeight.w900, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Dashed divider ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: List.generate(
                40,
                (_) => Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),

          // ── QR Code section ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              children: [
                // QR Code — PENTING: data = booking.id (doc ID, sama yang dipakai scanner Mitra)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: QrImageView(
                    data: booking.id, // Doc ID — HARUS sama dengan yang di-scan oleh validateAndCompleteBooking
                    version: QrVersions.auto,
                    size: 200,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0F5A3C),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A1A2E),
                    ),
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 16),

                // Booking ID
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPage,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.bookingId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.2,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info ringkasan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Column(
                    children: [
                      Row(children: [
                        const Icon(Icons.stadium_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(booking.fieldName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(dateStr, style: const TextStyle(fontSize: 13)),
                        const Text('  •  ', style: TextStyle(color: Colors.grey)),
                        Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Instruksi
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tunjukkan QR Code ini kepada petugas/Mitra lapangan saat Anda tiba.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, BookingModel booking) {
    final status = BookingStatusParsing.fromString(booking.status);
    return Column(children: [
      if (status == BookingStatus.menungguBayar) ...[
        ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentUploadPage(booking: booking))),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 12),
      ],
      if (status == BookingStatus.dikonfirmasi || status == BookingStatus.aktif) ...[
        ElevatedButton.icon(
          onPressed: () => _showETicketSheet(context, booking),
          icon: const Icon(Icons.qr_code_2, size: 20),
          label: const Text('Lihat E-Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.phone_outlined),
        label: const Text('Hubungi Pemilik Lapangan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      if (status == BookingStatus.menungguBayar || status == BookingStatus.menungguKonfirmasi) ...[
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => _cancelBooking(context, ref, booking.id),
          child: Text('Batalkan Pesanan', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        ),
      ],
    ]);
  }
  void _showETicketSheet(BuildContext context, BookingModel booking) {
    final dateStr = DateFormat('EEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.length > 1
        ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]} WIB'
        : '${booking.timeSlots.first} WIB';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.confirmation_number, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-Ticket', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                      Text('Tunjukkan ke petugas lapangan', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF0F5A3C), size: 14),
                      SizedBox(width: 4),
                      Text('LUNAS', style: TextStyle(color: Color(0xFF0F5A3C), fontWeight: FontWeight.w900, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: QrImageView(
                data: booking.id,
                version: QrVersions.auto,
                size: 220,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F5A3C),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Booking ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundPage,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(booking.bookingId,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: AppColors.textDark)),
            ),
            const SizedBox(height: 20),

            // Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.stadium_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(booking.fieldName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Instruksi
            Row(children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Tunjukkan QR Code ini kepada petugas/Mitra lapangan saat Anda tiba.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final confirm = await ConfirmationDialog.show(
      context: context,
      title: 'Batalkan Pesanan?',
      message: 'Apakah Anda yakin ingin membatalkan pesanan ini?',
      confirmText: 'Ya, Batalkan',
      isDestructive: true,
    );
    if (!confirm) return;
    try {
      await ref.read(bookingServiceProvider).cancelBooking(bookingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan dibatalkan'), backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showBuktiTransferDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white)),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
