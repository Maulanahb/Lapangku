import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapangku/core/services/firestore_service.dart';
import 'package:lapangku/utils/snackbar_helper.dart';
import 'package:email_otp/email_otp.dart';

class MitraWaitingPage extends ConsumerStatefulWidget {
  const MitraWaitingPage({super.key});

  @override
  ConsumerState<MitraWaitingPage> createState() => _MitraWaitingPageState();
}

class _MitraWaitingPageState extends ConsumerState<MitraWaitingPage> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;
    final status = (user?.statusVerifikasi ?? 'menunggu').toLowerCase().trim();
    final isRejected = status == 'ditolak';

    const primary = Color(0xFF1B6B3A);
    const redColor = Color(0xFFE04443);

    final displayColor = isRejected ? redColor : primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Hourglass Icon with background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: displayColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isRejected ? Icons.cancel_rounded : Icons.hourglass_empty_rounded,
                    size: 64,
                    color: displayColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                isRejected ? 'Pendaftaran Ditolak' : 'Menunggu Verifikasi',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                isRejected 
                  ? 'Maaf, data Anda tidak memenuhi syarat atau terdapat kesalahan. Silakan hubungi admin LapangKu.' 
                  : 'Tim kami sedang meninjau data kamu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              // Estimation Chip (Only if not rejected)
              if (!isRejected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_filled_rounded,
                          size: 18, color: primary),
                      SizedBox(width: 8),
                      Text(
                        'Estimasi 1–2 hari kerja',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Actions
              if (isRejected)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _showEmailOtpConfirmation(context, redColor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: redColor.withOpacity(0.4),
                    ),
                    child: const Text(
                      'Daftar Ulang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isRejected) const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRejected ? Colors.white : primary,
                    foregroundColor: isRejected ? Colors.grey.shade700 : Colors.white,
                    side: isRejected ? BorderSide(color: Colors.grey.shade300) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: isRejected ? 0 : 8,
                    shadowColor: isRejected ? Colors.transparent : primary.withOpacity(0.4),
                  ),
                  child: Text(
                    isRejected ? 'Keluar' : 'Kembali ke Beranda',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEmailOtpConfirmation(BuildContext context, Color redColor) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) return;

    final email = currentUser.email!;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OtpConfirmationSheet(
        email: email,
        redColor: redColor,
        onVerified: () => _performDeleteAndReRegister(currentUser),
      ),
    );
  }

  Future<void> _performDeleteAndReRegister(User currentUser) async {
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Delete from Firestore
      await FirestoreService.instance.collection('mitra').doc(currentUser.uid).delete();
      await FirestoreService.instance.collection('users').doc(currentUser.uid).delete();
      
      // Delete from Auth
      try {
        await currentUser.delete();
      } on FirebaseAuthException catch (e) {
        // If requires-recent-login, still proceed with logout
        // The auth account will remain but Firestore data is already deleted
        if (e.code != 'requires-recent-login') rethrow;
      }
      
      // Logout from local state
      ref.read(authProvider.notifier).logout();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        SnackbarHelper.showSuccess(context, 'Akun lama berhasil dihapus. Silakan daftar ulang.');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        SnackbarHelper.showError(context, 'Terjadi kesalahan: $e');
      }
    }
  }
}

// Stateful bottom sheet for OTP verification
class _OtpConfirmationSheet extends StatefulWidget {
  final String email;
  final Color redColor;
  final VoidCallback onVerified;

  const _OtpConfirmationSheet({
    required this.email,
    required this.redColor,
    required this.onVerified,
  });

  @override
  State<_OtpConfirmationSheet> createState() => _OtpConfirmationSheetState();
}

class _OtpConfirmationSheetState extends State<_OtpConfirmationSheet> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isSendingOtp = false;
  bool _isOtpSent = false;
  bool _isVerifying = false;
  int _resendTimer = 0;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-send OTP on open
    _sendOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });
    try {
      EmailOTP.config(
        appName: "LapangKu Mitra",
        otpType: OTPType.numeric,
        otpLength: 6,
        appEmail: 'lapangku1@gmail.com',
      );

      EmailOTP.setTemplate(
        template: '''
          <div style="background-color: #f6f9fc; padding: 40px 20px; font-family: 'Helvetica Neue', Arial, sans-serif;">
            <div style="max-width: 450px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.05);">
              <div style="background-color: #E04443; padding: 30px; text-align: center;">
                <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 800; letter-spacing: 1px;">LAPANGKU</h1>
              </div>
              <div style="padding: 40px 35px;">
                <h2 style="color: #E04443; margin: 0 0 15px; font-size: 20px; font-weight: 700;">Konfirmasi Hapus Akun</h2>
                <p style="color: #4a5568; line-height: 1.6; margin: 0 0 25px; font-size: 16px;">Anda meminta untuk menghapus akun dan mendaftar ulang. Masukkan kode berikut untuk konfirmasi:</p>
                
                <div style="background-color: #f7fafc; border: 1px dashed #cbd5e0; border-radius: 12px; padding: 25px; text-align: center; margin-bottom: 30px;">
                  <span style="font-size: 36px; font-weight: 900; letter-spacing: 10px; color: #E04443;">{{otp}}</span>
                </div>
                
                <p style="margin-top: 20px; color: #718096; font-size: 12px; line-height: 1.5;">Jika Anda tidak meminta ini, abaikan email ini.</p>
                <hr style="border: 0; border-top: 1px solid #edf2f7; margin: 25px 0;">
                <p style="font-size: 11px; color: #a0aec0; text-align: center;">© 2026 LapangKu Team</p>
              </div>
            </div>
          </div>
        ''',
      );

      final success = await EmailOTP.sendOTP(email: widget.email);
      if (success) {
        setState(() => _isOtpSent = true);
        _startResendTimer();
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Kode OTP telah dikirim ke ${widget.email}');
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage = 'Gagal mengirim OTP. Coba lagi.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyAndProceed() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length != 6) {
      setState(() => _errorMessage = 'Masukkan 6 digit kode OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Small delay so loading UI can render (EmailOTP.verifyOTP is synchronous)
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final res = EmailOTP.verifyOTP(otp: otpCode);

      if (res) {
        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          widget.onVerified();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Kode OTP salah. Silakan coba lagi.';
            for (var c in _otpControllers) {
              c.clear();
            }
            _otpFocusNodes[0].requestFocus();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpFilled = _otpControllers.every((c) => c.text.isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.redColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.email_outlined, size: 32, color: widget.redColor),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Konfirmasi Email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Kode verifikasi telah dikirim ke',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.redColor,
              ),
            ),
            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: widget.redColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: widget.redColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // OTP Input Fields
            if (_isSendingOtp)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      height: 54,
                      margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: widget.redColor,
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: const Color(0xFFF7FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: widget.redColor, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          if (value.isNotEmpty && index < 5) {
                            _otpFocusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _otpFocusNodes[index - 1].requestFocus();
                          }

                          // Auto-submit when all 6 digits are filled
                          if (_otpControllers.every((c) => c.text.isNotEmpty) && !_isVerifying) {
                            _verifyAndProceed();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Resend timer
              if (_resendTimer > 0)
                Text(
                  'Kirim ulang dalam $_resendTimer detik',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                )
              else
                TextButton(
                  onPressed: _isSendingOtp ? null : _sendOtp,
                  child: Text(
                    'Kirim Ulang OTP',
                    style: TextStyle(
                      color: widget.redColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying 
                      ? null 
                      : () {
                          if (!otpFilled) {
                            SnackbarHelper.showError(context, 'Masukkan 6 digit kode OTP');
                          } else {
                            _verifyAndProceed();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.redColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: widget.redColor.withOpacity(0.3),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Konfirmasi & Hapus Akun',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
