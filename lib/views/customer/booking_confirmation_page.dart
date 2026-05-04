import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

class BookingConfirmationPage extends ConsumerStatefulWidget {
  final FieldModel field;
  final DateTime selectedDate;
  final List<String> selectedTimeSlots;

  const BookingConfirmationPage({
    super.key,
    required this.field,
    required this.selectedDate,
    required this.selectedTimeSlots,
  });

  @override
  ConsumerState<BookingConfirmationPage> createState() => _State();
}

class _State extends ConsumerState<BookingConfirmationPage> {
  String _selectedPaymentMethod = 'bca';
  bool _isBooking = false;
  final int _biayaLayanan = 5000;

  int get _durasi => widget.selectedTimeSlots.length;
  int get _hargaLapangan => widget.field.hargaPerJam * _durasi;
  int get _totalBayar => _hargaLapangan + _biayaLayanan;

  String _fmt(int h) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(h);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A), fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B6B3A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldInfo(),
            const SizedBox(height: 16),
            _buildBookingDetails(),
            const SizedBox(height: 16),
            _buildPaymentSummary(),
            const SizedBox(height: 16),
            _buildPaymentMethods(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildFieldInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: widget.field.fotoUtama.isNotEmpty 
                  ? NetworkImage(widget.field.fotoUtama) as ImageProvider 
                  : const AssetImage('assets/images/placeholder.png'),
                fit: BoxFit.cover,
                onError: (_, __) => const AssetImage('assets/images/placeholder.png'),
              ),
              color: const Color(0xFFE8F5EC),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.field.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF718096)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(widget.field.alamat, style: const TextStyle(fontSize: 12, color: Color(0xFF718096)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(widget.selectedDate);
    // Asumsikan timeslots disortir, ambil start time dari pertama dan end time dari terakhir
    final startTime = widget.selectedTimeSlots.first.split(' - ')[0];
    final endTime = widget.selectedTimeSlots.last.split(' - ')[1];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailItem(Icons.calendar_today_outlined, 'Tanggal', dateStr)),
              Expanded(child: _buildDetailItem(Icons.access_time_outlined, 'Waktu', '$startTime - $endTime WIB')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDetailItem(Icons.timer_outlined, 'Durasi', '$_durasi Jam')),
              Expanded(child: _buildDetailItem(Icons.sports_soccer_outlined, 'Olahraga', widget.field.kategori)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B6B3A)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Harga lapangan', style: TextStyle(color: Color(0xFF718096))),
              Text(_fmt(_hargaLapangan), style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biaya layanan', style: TextStyle(color: Color(0xFF718096))),
              Text(_fmt(_biayaLayanan), style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_fmt(_totalBayar), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B6B3A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        _buildPaymentOption('bca', 'BCA Virtual Account', 'BCA'),
        _buildPaymentOption('gopay', 'GoPay', 'GoPay'),
        _buildPaymentOption('qris', 'QRIS', 'QRIS'),
        _buildPaymentOption('ovo', 'OVO', 'OVO'),
      ],
    );
  }

  Widget _buildPaymentOption(String id, String name, String badgeLabel) {
    final isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF1B6B3A) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badgeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1A365D))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1B6B3A), size: 20)
            else const Icon(Icons.circle_outlined, color: Color(0xFFCBD5E0), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
              const SizedBox(height: 2),
              Text(_fmt(_totalBayar), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
            ],
          ),
          ElevatedButton(
            onPressed: _isBooking ? null : _handleBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6B3A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isBooking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    children: [
                      Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(width: 8),
                      Icon(Icons.shopping_cart_checkout, size: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isBooking = true);
    try {
      final service = ref.read(bookingServiceProvider);
      
      final booking = await service.createBooking(
        field: widget.field,
        user: user,
        date: widget.selectedDate,
        timeSlots: widget.selectedTimeSlots,
        metodePembayaran: _selectedPaymentMethod,
        biayaLayanan: _biayaLayanan,
      );

      if (mounted) {
        setState(() => _isBooking = false);
        // Navigate to payment upload page
        Navigator.pushReplacementNamed(
          context, 
          '/payment-upload',
          arguments: booking,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
