import 'package:flutter/material.dart';

class Step2Password extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const Step2Password({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<Step2Password> createState() => _Step2PasswordState();
}

class _Step2PasswordState extends State<Step2Password> {
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          'Buat Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A202C),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Silakan masukkan password untuk akun kamu.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF718096),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        // Label: Password Baru
        const Text(
          'Password Baru',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 10),
        _buildPasswordField(
          controller: widget.passwordController,
          hint: 'Masukkan password baru',
          isVisible: _isPasswordVisible,
          onToggle: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),

        const SizedBox(height: 16),
        // Password Requirements
        _buildRequirementItem('Minimal 8 karakter'),
        _buildRequirementItem('Kombinasi huruf dan angka'),

        const SizedBox(height: 32),

        // Label: Konfirmasi Password Baru
        const Text(
          'Konfirmasi Password Baru',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 10),
        _buildPasswordField(
          controller: widget.confirmPasswordController,
          hint: 'Ketik ulang password baru',
          isVisible: _isConfirmVisible,
          onToggle: () =>
              setState(() => _isConfirmVisible = !_isConfirmVisible),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFCBD5E0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF), // Light blue background from image
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.lock_outline_rounded,
                color: Color(0xFFCBD5E0), size: 24),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: const Color(0xFFCBD5E0),
              size: 24,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}
