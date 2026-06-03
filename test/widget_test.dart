import 'package:flutter_test/flutter_test.dart';
import 'package:lapangku/models/booking/booking_model.dart';

void main() {
  group('BookingModel & BookingStatusHelper Tests', () {
    test('BookingStatusHelper validation rules', () {
      // Valid transitions
      expect(
        BookingStatusHelper.isValidTransition(
          BookingStatusHelper.menungguBayar,
          BookingStatusHelper.dikonfirmasi,
        ),
        isTrue,
      );
      expect(
        BookingStatusHelper.isValidTransition(
          BookingStatusHelper.dikonfirmasi,
          BookingStatusHelper.selesai,
        ),
        isTrue,
      );

      // Invalid transitions
      expect(
        BookingStatusHelper.isValidTransition(
          BookingStatusHelper.selesai,
          BookingStatusHelper.menungguBayar,
        ),
        isFalse,
      );
    });

    test('BookingModel instantiation and copyWith', () {
      final now = DateTime.now();
      final booking = BookingModel(
        id: 'test_id',
        bookingId: 'LPK-20260603-001',
        fieldId: 'field_123',
        mitraId: 'mitra_456',
        fieldName: 'Lapangan Futsal A',
        fieldAddress: 'Jl. Merdeka No. 10',
        fieldCategory: 'Futsal',
        fieldImageUrl: 'https://example.com/image.png',
        userId: 'user_789',
        userName: 'John Doe',
        tanggal: now,
        timeSlots: const ['08:00 - 09:00'],
        durasi: 1,
        hargaLapangan: 50000,
        biayaLayanan: 2000,
        totalBayar: 52000,
        metodePembayaran: 'midtrans',
        status: BookingStatusHelper.menungguBayar,
        statusTimeline: const [],
        batasWaktuBayar: now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
      );

      expect(booking.id, 'test_id');
      expect(booking.totalBayar, 52000);
      expect(booking.isActive, isTrue);

      final updatedBooking = booking.copyWith(status: BookingStatusHelper.dikonfirmasi);
      expect(updatedBooking.status, BookingStatusHelper.dikonfirmasi);
      expect(updatedBooking.id, 'test_id');
    });
  });
}
