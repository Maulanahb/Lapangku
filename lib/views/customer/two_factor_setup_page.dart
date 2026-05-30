import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/controllers/customer/customer_security_controller.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';

class TwoFactorSetupPage extends ConsumerStatefulWidget {
  const TwoFactorSetupPage({super.key});

  @override
  ConsumerState<TwoFactorSetupPage> createState() => _TwoFactorSetupPageState();
}

class _TwoFactorSetupPageState extends ConsumerState<TwoFactorSetupPage> {
  late final String _secretKey;
  late final String _qrUri;
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final controller = ref.read(customerSecurityControllerProvider.notifier);
    final user = ref.read(authStateProvider).value;
    final email = user?.email ?? 'user@lapangku.com';

    _secretKey = controller.generateSecretKey();
    _qrUri = controller.generateQrCodeUri(email: email, secret: _secretKey);
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _secretKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Secret Key disalin ke papan klip')),
    );
  }

  Future<void> _verifyAndActivate() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(customerSecurityControllerProvider.notifier);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final code = _otpController.text.trim();
    LoadingOverlay.show(context, message: 'Memverifikasi kode...');

    // Simulate short delay for premium feel
    await Future.delayed(const Duration(milliseconds: 500));

    final isValid = controller.verifyTOTPCode(_secretKey, code);

    if (mounted) {
      LoadingOverlay.dismiss(context);
      if (isValid) {
        try {
          await controller.updateTwoFactorStatus(
            uid: user.uid,
            enabled: true,
            secret: _secretKey,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Verifikasi 2 Langkah (2FA) berhasil diaktifkan!'),
                backgroundColor: AppColors.statusConfirmed,
              ),
            );
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menyimpan: $e')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Kode OTP tidak valid atau salah. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text(
          'Setup Verifikasi 2 Langkah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.security_outlined,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Langkah Setup 2FA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hubungkan akun LapangKu dengan aplikasi authenticator (Google Authenticator atau Microsoft Authenticator).',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // STEP 1 QR CODE
              _buildStepCard(
                step: '1',
                title: 'Scan QR Code',
                description:
                    'Scan QR Code di bawah menggunakan aplikasi authenticator Anda.',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: QrImageView(
                    data: _qrUri,
                    version: QrVersions.auto,
                    size: 180.0,
                    errorStateBuilder: (cxt, err) {
                      return const Center(child: Text('Gagal membuat QR Code'));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // STEP 2 MANUAL KEY
              _buildStepCard(
                step: '2',
                title: 'Masukkan Kode Manual',
                description:
                    'Jika tidak bisa men-scan QR, masukkan kunci rahasia ini secara manual ke authenticator.',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _secretKey,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1.5,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy,
                            color: AppColors.primary, size: 20),
                        tooltip: 'Salin Kunci',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // STEP 3 VERIFY OTP
              _buildStepCard(
                step: '3',
                title: 'Verifikasi & Aktifkan',
                description:
                    'Masukkan 6 digit kode dari aplikasi authenticator Anda untuk konfirmasi.',
                child: TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(
                        color: AppColors.hint.withValues(alpha: 0.5),
                        letterSpacing: 8),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.error, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode wajib diisi';
                    }
                    if (value.trim().length != 6 ||
                        int.tryParse(value) == null) {
                      return 'Kode harus berupa 6 digit angka';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifyAndActivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Verifikasi & Aktifkan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: child),
        ],
      ),
    );
  }
}
