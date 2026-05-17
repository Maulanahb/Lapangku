import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:lapangku/views/customer/payment_upload_page.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/models/booking_status.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';
import 'package:lapangku/views/customer/widgets/e_ticket_widget.dart';
import 'package:lapangku/standards/widgets/cached_image_widget.dart';
import 'package:lapangku/standards/widgets/shimmer_loading.dart';

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
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ShimmerLoading.card(height: 120),
            ShimmerLoading.card(height: 200),
            ShimmerLoading.card(height: 100),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (booking) {
          if (booking == null) return const Center(child: Text('Booking tidak ditemukan'));
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(booking),
                if (booking.isRescheduleRequested && booking.rescheduleStatus == 'pending')
                  _buildRescheduleBanner(booking),
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

  Widget _buildRescheduleBanner(BookingModel booking) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.pending_actions, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengajuan Reschedule Menunggu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                Text('Menunggu persetujuan Mitra lapangan.', style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
              ],
            ),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: CachedImageWidget(
            imageUrl: booking.fieldImageUrl,
            height: 140,
            width: double.infinity,
            errorWidget: _placeholderImage(),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: ETicketWidget(booking: booking),
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
        if (booking.isTicketExpired)
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.warning_amber_rounded, size: 20),
            label: const Text('E-Ticket Hangus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400, foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
          )
        else
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
        onPressed: () async {
          try {
            final doc = await FirebaseFirestore.instance.collection('users').doc(booking.mitraId).get();
            final data = doc.data();
            if (data != null && data['phone'] != null && data['phone'].toString().isNotEmpty) {
              String phone = data['phone'].toString();
              if (phone.startsWith('0')) {
                phone = '62${phone.substring(1)}';
              } else if (phone.startsWith('+62')) {
                phone = '62${phone.substring(3)}';
              }
              final url = Uri.parse('https://wa.me/$phone');
              final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')));
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor kontak pemilik lapangan belum tersedia.')));
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengambil data pemilik lapangan.')));
            }
          }
        },
        icon: const Icon(Icons.chat_outlined),
        label: const Text('Chat Pemilik Lapangan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      if ((status == BookingStatus.dikonfirmasi || status == BookingStatus.menungguKonfirmasi) && 
          !booking.isRescheduleRequested && 
          _isEligibleForReschedule(booking)) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showRescheduleSheet(context, ref, booking),
          icon: const Icon(Icons.edit_calendar),
          label: const Text('Ajukan Reschedule'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange.shade700, side: BorderSide(color: Colors.orange.shade700),
            padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
      if (status == BookingStatus.menungguBayar || status == BookingStatus.menungguKonfirmasi) ...[
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => _cancelBooking(context, ref, booking.id),
          child: Text('Batalkan Pesanan', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        ),
      ],
    ]);
  }

  bool _isEligibleForReschedule(BookingModel booking) {
    if (booking.timeSlots.isEmpty) return false;
    final startTimeStr = booking.timeSlots.first.split(' - ')[0];
    final parts = startTimeStr.split(':');
    if (parts.length >= 2) {
      final startHour = int.tryParse(parts[0]) ?? 0;
      final startMinute = int.tryParse(parts[1]) ?? 0;
      final startDateTime = DateTime(
        booking.tanggal.year,
        booking.tanggal.month,
        booking.tanggal.day,
        startHour,
        startMinute,
      );
      return startDateTime.difference(DateTime.now()).inHours >= 2;
    }
    return false;
  }

  void _showETicketSheet(BuildContext context, BookingModel booking) {
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
            ETicketWidget(booking: booking),
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
                child: CachedImageWidget(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  errorWidget: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white)),
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

  void _showRescheduleSheet(BuildContext context, WidgetRef ref, BookingModel booking) async {
    // Tampilkan loading saat fetch data lapangan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    List<String> times = [];
    try {
      final doc = await FirebaseFirestore.instance.collection('fields').doc(booking.fieldId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final jamBuka = data['jamBuka'] ?? '08:00';
        final jamTutup = data['jamTutup'] ?? '22:00';
        
        int startHour = 8;
        int endHour = 22;
        try {
          startHour = int.parse(jamBuka.toString().split(':')[0]);
          endHour = int.parse(jamTutup.toString().split(':')[0]);
        } catch (_) {}

        if (endHour <= startHour) endHour += 24;
        
        times = List.generate(endHour - startHour + 1, (i) {
          final h = startHour + i;
          return '${(h % 24).toString().padLeft(2, '0')}:00';
        });
      }
    } catch (_) {}

    if (!context.mounted) return;
    Navigator.pop(context); // Tutup loading

    if (times.isEmpty) {
      // Fallback statis jika gagal
      times = List.generate(17, (i) => '${(i + 6).toString().padLeft(2, '0')}:00');
    }

    DateTime? selectedDate;
    String? selectedStartTime;
    String? selectedEndTime;
    final reasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Ajukan Reschedule', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('Perubahan jadwal harus diajukan maksimal 2 jam sebelum waktu bermain Anda saat ini.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  
                  // Date Picker
                  const Text('Pilih Tanggal Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) setState(() => selectedDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedDate != null ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(selectedDate!) : 'Pilih Tanggal', style: TextStyle(color: selectedDate != null ? Colors.black87 : Colors.grey)),
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Time Picker (Simple Dropdown)
                  const Text('Pilih Jam Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text('Mulai'),
                              value: selectedStartTime,
                              items: times.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => selectedStartTime = v),
                            ),
                          ),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text('Selesai'),
                              value: selectedEndTime,
                              items: times.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => selectedEndTime = v),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Reason
                  const Text('Alasan Reschedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan alasan Anda...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedDate == null || selectedStartTime == null || selectedEndTime == null || reasonCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua data')));
                        return;
                      }
                      
                      // Cek durasi (harus sama atau lebih besar? Kita asumsikan format durasi tidak diubah total harganya, jadi sebaiknya sama, tapi untuk MVP kita langsung terima)
                      final timeSlotStr = '$selectedStartTime - $selectedEndTime';
                      
                      Navigator.pop(context); // Close sheet
                      try {
                        await ref.read(bookingServiceProvider).requestReschedule(
                          booking.id, 
                          selectedDate!, 
                          [timeSlotStr], 
                          reasonCtrl.text
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan reschedule berhasil dikirim'), backgroundColor: AppColors.primary));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Kirim Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
