import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/models/booking_status.dart';
import 'package:lapangku/standards/utils/currency_formatter.dart';
import 'package:lapangku/standards/widgets/confirmation_dialog.dart';
import 'package:lapangku/controllers/field/field_controller.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/core/services/firestore_service.dart';

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
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final bookingAsync =
                    ref.read(activeBookingStreamProvider(bookingId));
                final booking = bookingAsync.valueOrNull;
                if (booking == null) return;
                final dateStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID')
                    .format(booking.tanggal);
                final timeStr = booking.timeSlots.length > 1
                    ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]} WIB'
                    : '${booking.timeSlots.first} WIB';
                final status = BookingStatusParsing.fromString(booking.status);
                Share.share(
                  '🏟️ *Booking Lapangku Berhasil!* 🏟️\n\n'
                  '🎫 *ID Pesanan:* #${booking.bookingId}\n'
                  '⚽ *Lapangan:* ${booking.fieldName}\n'
                  '📍 *Alamat:* ${booking.fieldAddress}\n'
                  '📅 *Hari/Tanggal:* $dateStr\n'
                  '🕐 *Waktu:* $timeStr\n'
                  '💳 *Total Bayar:* ${CurrencyFormatter.format(booking.totalBayar)}\n'
                  '📌 *Status:* ${status.label}\n\n'
                  'Tunjukkan tiket Anda di aplikasi atau buka tautan ini:\n'
                  '🔗 lapangku://booking-detail?id=${booking.id}',
                );
              })
        ],
      ),
      body: bookingStream.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (booking) {
          if (booking == null)
            return const Center(child: Text('Booking tidak ditemukan'));
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(booking),
                if (booking.isRescheduleRequested &&
                    booking.rescheduleStatus == 'pending')
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
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 4),
        Text('#${booking.bookingId}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        if (status == BookingStatus.menungguBayar)
          _PaymentCountdownText(batasWaktuBayar: booking.batasWaktuBayar),
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
                Text('Pengajuan Reschedule Menunggu',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900)),
                Text('Menunggu persetujuan Mitra lapangan.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.orange.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInfoCard(BookingModel booking) {
    final dateStr =
        DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.length > 1
        ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]}'
        : booking.timeSlots.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: booking.fieldImageUrl.isNotEmpty
              ? Image.network(booking.fieldImageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImage())
              : _placeholderImage(),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.fieldName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(booking.fieldAddress,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: AppColors.backgroundPage,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Jadwal Main',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text('$dateStr • $timeStr',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark)),
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
      child: const Center(
          child: Icon(Icons.stadium_outlined,
              size: 48, color: AppColors.primary)));

  Widget _buildStatusTimeline(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Status Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        _buildTimelineItem('Pesanan Dibuat', booking, 'menunggu_bayar', true),
        _buildTimelineItem('Pembayaran Dikonfirmasi', booking, 'dikonfirmasi',
            booking.status != 'menunggu_bayar'),
        _buildTimelineItem(
            'Pesanan Aktif',
            booking,
            'aktif',
            booking.status == 'dikonfirmasi' ||
                booking.status == 'aktif' ||
                booking.status == 'selesai',
            isLast: false,
            badge: 'AKTIF'),
        _buildTimelineItem(
            'Selesai', booking, 'selesai', booking.status == 'selesai',
            isLast: true),
      ]),
    );
  }

  Widget _buildTimelineItem(
      String title, BookingModel booking, String targetStatus, bool isCompleted,
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
    if (badge == 'AKTIF' && booking.status == 'dikonfirmasi')
      timeStr = 'Sekarang';
    final isActiveBadge = badge != null && booking.status == 'dikonfirmasi';

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : AppColors.divider,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        if (!isLast)
          Container(
              width: 2,
              height: 30,
              color: isCompleted ? AppColors.primary : AppColors.divider),
      ]),
      const SizedBox(width: 16),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text(title,
                  style: TextStyle(
                      fontWeight:
                          isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? AppColors.textDark
                          : AppColors.textSecondary)),
              if (isActiveBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.statusPendingBg,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800)),
                ),
              ],
            ]),
            if (timeStr.isNotEmpty)
              Text(timeStr,
                  style: TextStyle(
                      fontSize: 12,
                      color: isActiveBadge
                          ? AppColors.primary
                          : AppColors.textSecondary)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildPaymentInfo(BuildContext context, BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Info Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Metode',
              style: TextStyle(color: AppColors.textSecondary)),
          Text(booking.metodePembayaran.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(color: AppColors.textSecondary)),
          Text(CurrencyFormatter.format(booking.totalBayar),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary)),
        ]),
      ]),
    );
  }

  Widget _buildETicketCard(BookingModel booking) {
    final dateStr =
        DateFormat('EEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.length > 1
        ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]}'
        : booking.timeSlots.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8)),
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
                  child: const Icon(Icons.confirmation_number,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-Ticket Anda',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                      Text('Tunjukkan ke petugas lapangan',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF0F5A3C), size: 14),
                      SizedBox(width: 4),
                      Text('LUNAS',
                          style: TextStyle(
                              color: Color(0xFF0F5A3C),
                              fontWeight: FontWeight.w900,
                              fontSize: 11)),
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
                    data: booking
                        .id, // Doc ID — HARUS sama dengan yang di-scan oleh validateAndCompleteBooking
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        const Icon(Icons.stadium_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(booking.fieldName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(dateStr, style: const TextStyle(fontSize: 13)),
                        const Text('  •  ',
                            style: TextStyle(color: Colors.grey)),
                        Text(timeStr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Instruksi
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tunjukkan QR Code ini kepada petugas/Mitra lapangan saat Anda tiba.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.3),
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

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, BookingModel booking) {
    final status = BookingStatusParsing.fromString(booking.status);
    return Column(children: [
      if (status == BookingStatus.menungguBayar) ...[
        ElevatedButton(
          onPressed: booking.paymentUrl != null
              ? () async {
                  final uri = Uri.parse(booking.paymentUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: const Text('Bayar Sekarang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 12),
      ],
      if (status == BookingStatus.dikonfirmasi ||
          status == BookingStatus.aktif) ...[
        if (booking.isTicketExpired)
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.warning_amber_rounded, size: 20),
            label: const Text('E-Ticket Hangus',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () => _showETicketSheet(context, booking),
            icon: const Icon(Icons.qr_code_2, size: 20),
            label: const Text('Lihat E-Ticket',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        onPressed: () async {
          if (booking.mitraId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID Mitra tidak ditemukan.')));
            return;
          }
          try {
            // Coba ambil dari koleksi 'mitra' yang merupakan data profil terbaru mitra
            final doc = await FirestoreService.instance
                .collection('mitra')
                .doc(booking.mitraId)
                .get();
            String phone = '';

            if (doc.exists) {
              final data = doc.data();
              if (data != null) {
                phone = data['phone'] ?? data['noTelepon'] ?? '';
              }
            }

            // Fallback: Jika tidak ada di 'mitra', coba cari di 'users' (saat daftar)
            if (phone.isEmpty) {
              final userDoc = await FirestoreService.instance
                  .collection('users')
                  .doc(booking.mitraId)
                  .get();
              if (userDoc.exists) {
                final userData = userDoc.data();
                if (userData != null) {
                  phone = userData['phone'] ?? userData['noTelepon'] ?? '';
                }
              }
            }

            if (phone.isNotEmpty) {
              // Format nomor HP untuk WhatsApp (hapus spasi, -, +, ganti 0 di depan jadi 62)
              phone = phone.replaceAll(RegExp(r'\D'), '');
              if (phone.startsWith('0')) {
                phone = '62${phone.substring(1)}';
              }
              final message =
                  'Halo, saya ${booking.userName} dengan ID Pesanan #${booking.bookingId} terkait lapangan ${booking.fieldName}.';
              final uri = Uri.parse(
                  'https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Tidak dapat membuka WhatsApp.')));
              }
            } else {
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Nomor telepon mitra tidak tersedia.')));
            }
          } catch (e) {
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengambil kontak: $e')));
          }
        },
        icon: const Icon(Icons.phone_outlined),
        label: const Text('Hubungi Pemilik Lapangan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      if (status == BookingStatus.dikonfirmasi &&
          booking.rescheduleStatus == null &&
          _isEligibleForReschedule(booking)) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showRescheduleSheet(context, ref, booking),
          icon: const Icon(Icons.edit_calendar),
          label: const Text('Ajukan Reschedule'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange.shade700,
            side: BorderSide(color: Colors.orange.shade700),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
      if (status == BookingStatus.menungguBayar) ...[
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => _cancelBooking(context, ref, booking.id),
          child: Text('Batalkan Pesanan',
              style: TextStyle(
                  color: Colors.red.shade700, fontWeight: FontWeight.bold)),
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
    final dateStr =
        DateFormat('EEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
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
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
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
                  child: const Icon(Icons.confirmation_number,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('E-Ticket',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 20)),
                      Text('Tunjukkan ke petugas lapangan',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF0F5A3C), size: 14),
                      SizedBox(width: 4),
                      Text('LUNAS',
                          style: TextStyle(
                              color: Color(0xFF0F5A3C),
                              fontWeight: FontWeight.w900,
                              fontSize: 11)),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.5,
                      color: AppColors.textDark)),
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
                  const Icon(Icons.stadium_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(booking.fieldName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.access_time,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(timeStr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Instruksi
            Row(children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Tunjukkan QR Code ini kepada petugas/Mitra lapangan saat Anda tiba.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(
      BuildContext context, WidgetRef ref, String bookingId) async {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pesanan dibatalkan'),
            backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showRescheduleSheet(
      BuildContext context, WidgetRef ref, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RescheduleBottomSheet(booking: booking),
    );
  }
}

class RescheduleBottomSheet extends ConsumerStatefulWidget {
  final BookingModel booking;
  const RescheduleBottomSheet({super.key, required this.booking});

  @override
  ConsumerState<RescheduleBottomSheet> createState() =>
      _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends ConsumerState<RescheduleBottomSheet> {
  DateTime? _selectedDate;
  final List<String> _selectedSlots = [];
  final TextEditingController _reasonCtrl = TextEditingController();
  final List<Map<String, dynamic>> _quickDates = [];

  int get _requiredSlotCount {
    if (widget.booking.timeSlots.isNotEmpty) {
      return widget.booking.timeSlots.length;
    }
    return widget.booking.durasi > 0 ? widget.booking.durasi : 1;
  }

  @override
  void initState() {
    super.initState();
    // Default to tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    final now = DateTime.now();
    final dayNames = ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];
    for (int i = 0; i < 14; i++) {
      final d = now.add(Duration(days: i));
      _quickDates.add({
        'day': dayNames[d.weekday % 7],
        'date': DateFormat('dd').format(d),
        'full': DateFormat('EEEE, dd MMM', 'id_ID').format(d),
        'iso': DateFormat('yyyy-MM-dd').format(d),
        'dateTime': DateTime(d.year, d.month, d.day),
      });
    }

    _reasonCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  List<String> _generateSlots(FieldModel field) {
    int startHour = 8;
    int endHour = 22;

    try {
      startHour = int.parse(field.jamBuka.split(':')[0]);
      endHour = int.parse(field.jamTutup.split(':')[0]);
    } catch (_) {}

    if (endHour <= startHour) {
      endHour += 24;
    }

    final int totalSlots = endHour - startHour;
    return List.generate(totalSlots, (i) {
      final h = startHour + i;
      final nextH = h + 1;

      final hStr = (h % 24).toString().padLeft(2, '0');
      final nextHStr = (nextH % 24).toString().padLeft(2, '0');

      return '$hStr:00 - $nextHStr:00';
    });
  }

  void _toggleSlot(String slot) {
    if (_selectedSlots.contains(slot)) {
      setState(() => _selectedSlots.remove(slot));
      return;
    }

    if (_selectedSlots.length >= _requiredSlotCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reschedule harus $_requiredSlotCount jam sesuai durasi pesanan awal.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _selectedSlots.add(slot);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fieldDetailAsync =
        ref.watch(fieldDetailProvider(widget.booking.fieldId));
    final isoDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final bookedSlotsKey = '${widget.booking.fieldId}|$isoDateStr';
    final bookedSlotsAsync = ref.watch(bookedSlotsProvider(bookedSlotsKey));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.edit_calendar,
                    color: Colors.orange.shade800, size: 24),
                const SizedBox(width: 8),
                const Text('Ajukan Reschedule',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Perubahan jadwal harus diajukan maksimal 2 jam sebelum waktu bermain Anda saat ini.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildCurrentBookingCard(),
            const SizedBox(height: 20),
            const Text('Pilih Tanggal Baru',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _buildDatePickerRow(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pilih Jam Baru',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    _selectedSlots.isEmpty
                        ? 'Pilih $_requiredSlotCount Jam'
                        : '${_selectedSlots.length}/$_requiredSlotCount Jam',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            fieldDetailAsync.when(
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          CircularProgressIndicator(color: AppColors.primary))),
              error: (e, _) => Center(
                  child: Text('Gagal memuat detail lapangan: $e',
                      style: const TextStyle(color: Colors.red))),
              data: (field) {
                final allSlots = _generateSlots(field);

                return bookedSlotsAsync.when(
                  loading: () => const Center(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                              color: AppColors.primary))),
                  error: (e, _) => Center(
                      child: Text('Gagal memuat slot terbooking: $e',
                          style: const TextStyle(color: Colors.red))),
                  data: (bookedSlots) {
                    final isSameDay = _selectedDate!.year ==
                            widget.booking.tanggal.year &&
                        _selectedDate!.month == widget.booking.tanggal.month &&
                        _selectedDate!.day == widget.booking.tanggal.day;

                    final displayBookedSlots = isSameDay
                        ? bookedSlots
                            .where((s) => !widget.booking.timeSlots.contains(s))
                            .toList()
                        : bookedSlots;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(allSlots.length, (i) {
                            final slot = allSlots[i];
                            final isBooked = displayBookedSlots.contains(slot);
                            final isOriginalSlot = isSameDay &&
                                widget.booking.timeSlots.contains(slot);

                            bool isPassed = false;
                            final today = DateTime.now();
                            final isToday = _selectedDate!.year == today.year &&
                                _selectedDate!.month == today.month &&
                                _selectedDate!.day == today.day;

                            if (isToday) {
                              final startTimeStr = slot.split(' - ')[0];
                              final parts = startTimeStr.split(':');
                              if (parts.length >= 2) {
                                final hour = int.tryParse(parts[0]) ?? 0;
                                final minute = int.tryParse(parts[1]) ?? 0;
                                final startDateTime = DateTime(
                                  _selectedDate!.year,
                                  _selectedDate!.month,
                                  _selectedDate!.day,
                                  hour,
                                  minute,
                                );
                                if (DateTime.now().isAfter(startDateTime)) {
                                  isPassed = true;
                                }
                              }
                            }

                            final isUnavailable =
                                isBooked || isPassed || isOriginalSlot;
                            final isSel = _selectedSlots.contains(slot);

                            Color bg, border, txt;
                            String sub = '';
                            if (isOriginalSlot) {
                              bg = AppColors.backgroundPage;
                              border = Colors.grey.shade200;
                              txt = Colors.grey.shade400;
                              sub = 'JADWAL AWAL';
                            } else if (isBooked) {
                              bg = AppColors.backgroundPage;
                              border = Colors.grey.shade200;
                              txt = Colors.grey.shade400;
                              sub = 'TERPESAN';
                            } else if (isPassed) {
                              bg = AppColors.backgroundPage;
                              border = Colors.grey.shade200;
                              txt = Colors.grey.shade400;
                              sub = 'LEWAT';
                            } else if (isSel) {
                              bg = Colors.orange.shade700;
                              border = Colors.orange.shade700;
                              txt = Colors.white;
                              sub = 'TERPILIH';
                            } else {
                              bg = Colors.white;
                              border = Colors.orange.shade700;
                              txt = Colors.orange.shade700;
                            }

                            return GestureDetector(
                              onTap: isUnavailable
                                  ? null
                                  : () => _toggleSlot(slot),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width:
                                    (MediaQuery.of(context).size.width - 58) /
                                        2,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: border),
                                ),
                                child: Column(
                                  children: [
                                    Text(slot,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: txt)),
                                    if (sub.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          sub,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: isSel
                                                ? Colors.white70
                                                : txt.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Jam Terpilih: ${_selectedSlots.length}/$_requiredSlotCount Jam',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedSlots.length == _requiredSlotCount
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('Alasan Reschedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan Anda...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange.shade700)),
              ),
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBookingCard() {
    final originalDateStr =
        DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(widget.booking.tanggal);
    final originalTimeStr = widget.booking.timeSlots.length > 1
        ? '${widget.booking.timeSlots.first.split(' - ')[0]} - ${widget.booking.timeSlots.last.split(' - ')[1]}'
        : widget.booking.timeSlots.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jadwal Saat Ini:',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$originalDateStr • $originalTimeStr',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow() {
    final isCustomDateSelected = _selectedDate != null &&
        !_quickDates.any((d) =>
            d['dateTime'] ==
            DateTime(
                _selectedDate!.year, _selectedDate!.month, _selectedDate!.day));

    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...List.generate(_quickDates.length, (i) {
            final qDate = _quickDates[i];
            final isSel = _selectedDate != null &&
                _selectedDate!.year == qDate['dateTime'].year &&
                _selectedDate!.month == qDate['dateTime'].month &&
                _selectedDate!.day == qDate['dateTime'].day;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = qDate['dateTime'];
                  _selectedSlots.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSel ? Colors.orange.shade700 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isSel
                          ? Colors.orange.shade700
                          : Colors.grey.shade300),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      qDate['day']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      qDate['date']!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (isCustomDateSelected)
            GestureDetector(
              onTap: () => _pickCustomDate(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade700),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'PILIHAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM', 'id_ID').format(_selectedDate!),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _pickCustomDate(),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month,
                      color: AppColors.textSecondary, size: 24),
                  SizedBox(height: 4),
                  Text(
                    'Lainnya',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = DateTime(date.year, date.month, date.day);
        _selectedSlots.clear();
      });
    }
  }

  Widget _buildSubmitButton(BuildContext context) {
    final isValid = _selectedDate != null &&
        _selectedSlots.length == _requiredSlotCount &&
        _reasonCtrl.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid
            ? () async {
                final orderedSlots = List<String>.from(_selectedSlots)
                  ..sort((a, b) => a.compareTo(b));

                Navigator.pop(context);
                try {
                  await ref.read(bookingServiceProvider).requestReschedule(
                      widget.booking.id,
                      _selectedDate!,
                      orderedSlots,
                      _reasonCtrl.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pengajuan reschedule berhasil dikirim'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
        ),
        child: const Text('Kirim Pengajuan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

class _PaymentCountdownText extends StatefulWidget {
  final DateTime batasWaktuBayar;
  const _PaymentCountdownText({Key? key, required this.batasWaktuBayar})
      : super(key: key);

  @override
  State<_PaymentCountdownText> createState() => _PaymentCountdownTextState();
}

class _PaymentCountdownTextState extends State<_PaymentCountdownText> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    if (widget.batasWaktuBayar.isAfter(now)) {
      setState(() {
        _timeLeft = widget.batasWaktuBayar.difference(now);
      });
    } else {
      _timer?.cancel();
      setState(() {
        _timeLeft = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) return const SizedBox.shrink();

    final hours = _timeLeft.inHours.toString().padLeft(2, "0");
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, "0");
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, "0");

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text("Sisa waktu: $hours:$minutes:$seconds",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
