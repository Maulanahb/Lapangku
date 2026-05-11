import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/controllers/mitra/mitra_booking_provider.dart';
import 'package:lapangku/models/booking/booking_model.dart';

class MitraQrScannerPage extends ConsumerStatefulWidget {
  const MitraQrScannerPage({super.key});

  @override
  ConsumerState<MitraQrScannerPage> createState() => _MitraQrScannerPageState();
}

class _MitraQrScannerPageState extends ConsumerState<MitraQrScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  static const Color _primaryGreen = Color(0xFF0F5A3C);
  static const Color _lightGreen = Color(0xFFD1FAE5);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Dark overlay with cutout
          _buildOverlay(),

          // Top bar
          _buildTopBar(),

          // Bottom instructions
          _buildBottomPanel(),

          // Processing indicator
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan E-Ticket',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Arahkan kamera ke QR Code tiket',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _scannerController.toggleTorch(),
              icon: ValueListenableBuilder(
                valueListenable: _scannerController,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: state.torchState == TorchState.on
                        ? const Color(0xFFFFB800)
                        : Colors.white,
                  );
                },
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    const scanAreaSize = 260.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2 - 40;

        return Stack(
          children: [
            // Semi-transparent overlay
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: centerX - scanAreaSize / 2,
                    top: centerY - scanAreaSize / 2,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // Any color, will be cut out
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner decorations
            Positioned(
              left: centerX - scanAreaSize / 2,
              top: centerY - scanAreaSize / 2,
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: CustomPaint(
                  painter: _CornerPainter(color: _primaryGreen),
                ),
              ),
            ),

            // Animated scan line
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (context, child) {
                return Positioned(
                  left: centerX - scanAreaSize / 2 + 20,
                  top: (centerY - scanAreaSize / 2 + 10) +
                      (_scanLineAnim.value * (scanAreaSize - 20)),
                  child: Container(
                    width: scanAreaSize - 40,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _primaryGreen.withValues(alpha: 0.8),
                          _lightGreen,
                          _primaryGreen.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          28,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2, color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Posisikan QR Code di dalam kotak',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionChip(
                  icon: Icons.flip_camera_ios,
                  label: 'Ganti Kamera',
                  onTap: () => _scannerController.switchCamera(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFFD1FAE5),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Memvalidasi tiket...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    _validateTicket(rawValue);
  }

  Future<void> _validateTicket(String bookingId) async {
    try {
      final booking = await ref
          .read(MitraBookingActionsProvider.notifier)
          .validateTicket(bookingId);

      if (!mounted) return;
      _showSuccessDialog(booking);
    } catch (e) {
      if (!mounted) return;

      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      _showErrorDialog(errorMsg);
    }
  }

  void _showSuccessDialog(BookingModel booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: _lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: _primaryGreen, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tiket Valid! ✅',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Booking telah diselesaikan',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person_outline, 'Pelanggan',
                        booking.userName),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.stadium_outlined, 'Lapangan',
                        booking.fieldName),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Tanggal',
                      DateFormat('EEEE, d MMM yyyy', 'id_ID')
                          .format(booking.tanggal),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.access_time, 'Jam',
                        booking.timeSlots.join(', ')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Close scanner
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Selesai',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE8E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: Color(0xFFE04443), size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tiket Tidak Valid',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE04443),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Kembali',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _isProcessing = false);
                        _scannerController.start();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Scan Ulang',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for scanner corner decorations
class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 32.0;
    const radius = 24.0;

    // Top-left
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, radius * 2, radius * 2),
      3.14159, // pi
      1.5708, // pi/2
      false,
      paint,
    );
    canvas.drawLine(
        const Offset(0, radius), const Offset(0, cornerLength), paint);
    canvas.drawLine(
        const Offset(radius, 0), const Offset(cornerLength, 0), paint);

    // Top-right
    canvas.drawArc(
      Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2),
      -1.5708,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(size.width, radius),
        Offset(size.width, cornerLength), paint);
    canvas.drawLine(Offset(size.width - radius, 0),
        Offset(size.width - cornerLength, 0), paint);

    // Bottom-left
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2),
      1.5708,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(0, size.height - radius),
        Offset(0, size.height - cornerLength), paint);
    canvas.drawLine(Offset(radius, size.height),
        Offset(cornerLength, size.height), paint);

    // Bottom-right
    canvas.drawArc(
      Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2,
          radius * 2, radius * 2),
      0,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(size.width, size.height - radius),
        Offset(size.width, size.height - cornerLength), paint);
    canvas.drawLine(Offset(size.width - radius, size.height),
        Offset(size.width - cornerLength, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
