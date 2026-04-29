import 'package:flutter/material.dart';

class Step1Account extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController businessNameController;
  final TextEditingController phoneController;

  const Step1Account({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.businessNameController,
    required this.phoneController,
  });

  @override
  State<Step1Account> createState() => _Step1AccountState();
}

class _Step1AccountState extends State<Step1Account> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  InputDecoration _decor(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1B6B3A), width: 1.5)),
      labelStyle: TextStyle(color: Colors.grey.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Buat Akun Pemilik',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A202C)),
        ),
        const SizedBox(height: 6),
        Text(
          'Isi data di bawah untuk mendaftarkan bisnis Anda di LapangKu',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 28),

        // Nama Bisnis
        TextField(
          controller: widget.businessNameController,
          textCapitalization: TextCapitalization.words,
          decoration: _decor('Nama Bisnis / Lapangan', Icons.store_outlined),
        ),
        const SizedBox(height: 14),

        // Email
        TextField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _decor('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 14),

        // No. Telepon
        TextField(
          controller: widget.phoneController,
          keyboardType: TextInputType.phone,
          decoration: _decor('No. WhatsApp / Telepon', Icons.phone_outlined),
        ),
        const SizedBox(height: 14),

        // Password
        TextField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          decoration: _decor(
            'Password',
            Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Konfirmasi Password
        TextField(
          controller: widget.confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: _decor(
            'Konfirmasi Password',
            Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1B6B3A), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data akun akan digunakan untuk login dan verifikasi bisnis Anda oleh tim LapangKu.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF065F46),
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
