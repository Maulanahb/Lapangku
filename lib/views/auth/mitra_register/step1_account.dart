import 'package:flutter/material.dart';

class Step1Account extends StatelessWidget {
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final int resendTimer;
  final VoidCallback onResend;

  const Step1Account({
    super.key,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.resendTimer,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Verifikasi Akun',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan kode untuk mengamankan akun kamu',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 56,
              child: TextField(
                controller: otpControllers[index],
                focusNode: otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: "",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1B6B3A), width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        resendTimer > 0
            ? Text(
                'Kirim ulang dalam $resendTimer detik',
                style: const TextStyle(
                    color: Color(0xFFE53E3E), fontWeight: FontWeight.w500),
              )
            : TextButton(
                onPressed: onResend,
                child: const Text(
                  'Kirim ulang kode',
                  style: TextStyle(
                      color: Color(0xFF1B6B3A), fontWeight: FontWeight.bold),
                ),
              ),
      ],
    );
  }
}
