import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';

class ETicketWidget extends StatelessWidget {
  final BookingModel booking;
  
  const ETicketWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, dd MMM yyyy', 'id_ID').format(booking.tanggal);
    final timeStr = booking.timeSlots.length > 1
        ? '${booking.timeSlots.first.split(' - ')[0]} - ${booking.timeSlots.last.split(' - ')[1]} WIB'
        : '${booking.timeSlots.first} WIB';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
            data: booking.id, // ID dokumen untuk scan mitra
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundPage,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(booking.bookingId,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: AppColors.textDark)),
        ),
        const SizedBox(height: 20),

        // Info Lapangan
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
          ),
        ]),
      ],
    );
  }
}
