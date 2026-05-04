import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/booking/booking_model.dart';
import 'package:lapangku/controllers/booking/booking_controller.dart';

class PaymentUploadPage extends ConsumerStatefulWidget {
  final BookingModel booking;
  const PaymentUploadPage({super.key, required this.booking});

  @override
  ConsumerState<PaymentUploadPage> createState() => _State();
}

class _State extends ConsumerState<PaymentUploadPage> {
  Timer? _timer;
  Duration _timeLeft = const Duration();
  File? _imageFile;
  bool _isDummyImage = false;
  bool _isUploading = false;
  
  // Dummy bank details (Ideally from Firestore settings)
  final String _bankName = 'BCA';
  final String _accountNumber = '123-456-789-0';
  final String _accountName = 'LapangKu Indonesia';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTimeLeft();
        });
      }
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    if (widget.booking.batasWaktuBayar.isAfter(now)) {
      _timeLeft = widget.booking.batasWaktuBayar.difference(now);
    } else {
      _timeLeft = Duration.zero;
      _timer?.cancel();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  String _fmt(int h) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(h);

  @override
  Widget build(BuildContext context) {
    final isQris = widget.booking.metodePembayaran.toLowerCase() == 'qris';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Upload Bukti Bayar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A), fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B6B3A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTimerCard(),
            const SizedBox(height: 16),
            if (isQris) _buildQrisSection() else _buildTransferSection(),
            const SizedBox(height: 24),
            _buildHelpButton(),
          ],
        ),
      ),
      bottomSheet: isQris ? _buildQrisBottomBar() : _buildTransferBottomBar(),
    );
  }

  Widget _buildTimerCard() {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE5B4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Text('Selesaikan pembayaran sebelum:', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timeBox(hours, 'JAM'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
              _timeBox(minutes, 'MENIT'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
              _timeBox(seconds, 'DETIK'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
      ],
    );
  }

  Widget _buildTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detail Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildDetailRow('Bank', _bankName),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              _buildDetailRow('No. Rekening', _accountNumber, isCopyable: true),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              _buildDetailRow('Atas Nama', _accountName),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah Transfer', style: TextStyle(color: Color(0xFF718096))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt(widget.booking.totalBayar), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B6B3A))),
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 10, color: Colors.red),
                          SizedBox(width: 4),
                          Text('HARUS SESUAI!!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Foto Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: _isDummyImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF1B6B3A), size: 48),
                      const SizedBox(height: 8),
                      const Text('Foto Dummy Dipilih', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
                      const SizedBox(height: 4),
                      Text('Siap untuk diupload', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  )
                : _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_imageFile!, fit: BoxFit.cover),
                            Container(color: Colors.black.withOpacity(0.3)),
                            const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 48)),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Ketuk untuk ambil/pilih foto', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Format JPG, PNG (Max 5MB)', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 12),
        // TOMBOL DUMMY UNTUK TESTING
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _isDummyImage = true;
                _imageFile = null;
              });
            },
            icon: const Icon(Icons.bug_report, size: 16),
            label: const Text('Gunakan Foto Dummy (Testing)'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
          ),
        ),
        const SizedBox(height: 100), // padding for bottom bar
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isCopyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF718096))),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (isCopyable) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disalin ke clipboard!')));
                },
                child: const Icon(Icons.copy, size: 16, color: Color(0xFF1B6B3A)),
              ),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildQrisSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('LapangKu Indonesia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          // QRIS Image Placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade600, width: 4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(child: Icon(Icons.qr_code_2, size: 150, color: Colors.grey.shade800)),
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    color: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text('QRIS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan QR code di atas menggunakan\naplikasi e-wallet atau mobile banking kamu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF718096), fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(color: Color(0xFF718096))),
              Text(_fmt(widget.booking.totalBayar), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B6B3A))),
            ],
          ),
          const SizedBox(height: 80), // padding for bottom bar
        ],
      ),
    );
  }

  Widget _buildHelpButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.support_agent),
      label: const Text('Butuh bantuan? Hubungi CS'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1B6B3A),
        side: const BorderSide(color: Color(0xFF1B6B3A)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildTransferBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))]),
      child: ElevatedButton(
        onPressed: (_imageFile == null && !_isDummyImage) || _isUploading ? null : _handleUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B6B3A),
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isUploading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Upload & Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildQrisBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () {}, // Save QR functionality
            icon: const Icon(Icons.download),
            label: const Text('Simpan QR ke Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B6B3A),
              side: const BorderSide(color: Color(0xFF1B6B3A), width: 1.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isUploading ? null : _handleQrisPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6B3A),
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isUploading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Selesai Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpload() async {
    if (_imageFile == null && !_isDummyImage) return;

    setState(() => _isUploading = true);
    try {
      final service = ref.read(bookingServiceProvider);
      
      if (_isDummyImage) {
        await service.uploadDummyPaymentProof(widget.booking.id);
      } else {
        await service.uploadPaymentProof(widget.booking.id, _imageFile!);
      }

      if (mounted) {
        setState(() => _isUploading = false);
        _finishPayment();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Handle QRIS payment â€” update status ke menunggu_konfirmasi
  Future<void> _handleQrisPayment() async {
    setState(() => _isUploading = true);
    try {
      final service = ref.read(bookingServiceProvider);
      await service.confirmQrisPayment(widget.booking.id);

      if (mounted) {
        setState(() => _isUploading = false);
        _finishPayment();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal konfirmasi pembayaran: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _finishPayment() {
    // Navigate to booking detail
    Navigator.pushReplacementNamed(
      context, 
      '/booking-detail',
      arguments: widget.booking.id,
    );
  }
}
