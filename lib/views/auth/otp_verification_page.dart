import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_otp/email_otp.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'dart:async';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final Color primaryGreen = const Color(0xFF1B6B3A);

  bool _isVerifying = false;
  bool _isResending = false;
  bool _isSuccess = false; // Setelah OTP valid & reset email terkirim
  String _email = '';

  int _countdown = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _email.isEmpty) {
      _email = args;
    }
  }

  void _startCountdown() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otpCode;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan 6 digit kode OTP')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Verifikasi OTP dengan package email_otp
      final isValid = EmailOTP.verifyOTP(otp: otp);

      if (!mounted) return;

      if (isValid) {
        // OTP valid → kirim link reset password via Firebase
        await ref.read(authProvider.notifier).sendPasswordReset(_email);

        if (!mounted) return;
        final authState = ref.read(authProvider);

        if (authState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authState.errorMessage!)),
          );
          setState(() => _isVerifying = false);
          return;
        }

        // Sukses — tampilkan state berhasil
        setState(() {
          _isSuccess = true;
          _isVerifying = false;
        });
      } else {
        // OTP salah
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP salah. Periksa kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        // Clear input
        for (var c in _otpControllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
        setState(() => _isVerifying = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    try {
      EmailOTP.config(
        appName: 'LapangKu',
        otpType: OTPType.numeric,
        otpLength: 6,
        appEmail: 'lapangku1@gmail.com',
      );
      final success = await EmailOTP.sendOTP(email: _email);

      if (!mounted) return;

      if (success) {
        for (var c in _otpControllers) {
          c.clear();
        }
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode OTP baru dikirim ke $_email')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim ulang OTP')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isSuccess
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Verifikasi OTP',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
      body: SafeArea(
        child: _isSuccess ? _buildSuccessState() : _buildOtpForm(),
      ),
    );
  }

  Widget _buildOtpForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan Kode OTP',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              children: [
                const TextSpan(text: 'Kode OTP 6 digit telah dikirim ke\n'),
                TextSpan(
                  text: _email,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 6 OTP Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                height: 55,
                width: 50,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  onChanged: (value) {
                    if (value.length == 1 && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryGreen, width: 2),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Timer & Resend
          Center(
            child: _canResend
                ? TextButton(
                    onPressed: _isResending ? null : _resendOtp,
                    child: _isResending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Kirim Ulang Kode OTP',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  )
                : RichText(
                    text: TextSpan(
                      text: 'Kirim ulang dalam ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${_countdown}s',
                          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 48),

          // Tombol Verifikasi
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: primaryGreen.withValues(alpha: 0.6),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Text(
                      'Verifikasi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.mark_email_read_outlined, color: primaryGreen, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Verifikasi Berhasil!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Color(0xFF718096), height: 1.6),
              children: [
                const TextSpan(text: 'Link reset password telah dikirim ke\n'),
                TextSpan(
                  text: '$_email\n\n',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                ),
                const TextSpan(
                  text: 'Buka email kamu dan klik link tersebut\nuntuk membuat password baru.\n\n',
                ),
                const TextSpan(
                  text: '💡 Cek juga folder Spam jika tidak\nada di kotak masuk.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Kembali ke Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
