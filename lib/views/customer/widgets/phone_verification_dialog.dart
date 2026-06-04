import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/controllers/customer/customer_security_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationDialog extends ConsumerStatefulWidget {
  final String phoneNumber;

  const PhoneVerificationDialog({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<PhoneVerificationDialog> createState() => _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends ConsumerState<PhoneVerificationDialog> {
  String? _verificationId;
  bool _codeSent = false;
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifyPhone();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto resolve in some devices
          // We can just verify it directly
          try {
            await ref.read(customerSecurityControllerProvider.notifier).verifyPhoneOTP(
              verificationId: credential.verificationId ?? '',
              smsCode: credential.smsCode ?? '',
            );
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nomor HP berhasil diverifikasi secara otomatis!')),
              );
            }
          } catch (e) {
            // fail silently, let user input
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengirim OTP: ${e.message}')),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _submitOTP() async {
    if (_otpController.text.length < 6 || _verificationId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(customerSecurityControllerProvider.notifier).verifyPhoneOTP(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor HP berhasil diverifikasi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP salah atau kadaluarsa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.phone_android,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Verifikasi Nomor HP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? 'Masukkan 6 digit kode OTP yang telah dikirim ke ${widget.phoneNumber}'
                  : 'Mengirim kode OTP ke ${widget.phoneNumber}...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else if (_codeSent) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) {
                  if (v.length == 6) {
                    _submitOTP();
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _otpController.text.length == 6 ? _submitOTP : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Verifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _codeSent = false;
                    _otpController.clear();
                  });
                  _verifyPhone();
                },
                child: const Text('Kirim Ulang OTP', style: TextStyle(color: AppColors.primary)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
