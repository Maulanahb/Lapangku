import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/views/auth/mitra_register/mitra_register_page.dart';
import 'package:lapangku/core/utils/navigation_helper.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'customer'; // Default kembali ke customer (kiri)
  final _MitraContactController =
      TextEditingController(); // Controller khusus Mitra

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _MitraContactController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validasi
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak cocok')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return;
    }

    if (_selectedRole == 'admin') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun admin hanya bisa dibuat oleh sistem.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Trigger register
    await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);

    // Handle error
    if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.errorMessage!)),
      );
      return;
    }

    if (authState.user != null) {
      NavigationHelper.navigateByRole(context, authState.user!);
    }
  }

  Widget _buildToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Container(
                color: Colors.transparent,
                child: const Center(
                  child: Text('Masuk',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF718096))),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1))
                  ]),
              child: const Center(
                child: Text('Daftar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1B6B3A))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Header Top Bar
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B6B3A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LapangKu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B6B3A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Toggle
                _buildToggle(),
                const SizedBox(height: 32),

                // Register Type label
                const Text(
                  'Saya ingin mendaftar sebagai:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),

                // Role selector
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        role: 'customer',
                        title: 'Customer',
                        subtitle: 'booking lapangan',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleCard(
                        role: 'mitra',
                        title: 'Pemilik Lapangan',
                        subtitle: 'kelola lapangan',
                        icon: Icons.domain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Container for form fields
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  padding: const EdgeInsets.all(24),
                  child: _selectedRole == 'customer'
                      ? _buildCustomerForm(authState) // Form buatan teman Anda
                      : _buildMitraForm(), // Form khusus Mitra (OTP)
                ),

                const SizedBox(height: 32),
                // Bottom link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ',
                        style: TextStyle(color: Color(0xFF718096))),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Color(0xFF1B6B3A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
            filled: true,
            fillColor: const Color(0xFFF1F4F8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NOMOR HP',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('+62',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                        fontSize: 16)),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                      hintText: '812 3456 7890',
                      hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(bottom: 5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      {required TextEditingController controller,
      required String label,
      required bool obscure,
      required VoidCallback onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style:
              const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 2.0),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle:
                const TextStyle(color: Color(0xFFA0AEC0), letterSpacing: 2.0),
            filled: true,
            fillColor: const Color(0xFFF1F4F8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            suffixIcon: IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFA0AEC0)),
                onPressed: onToggle),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(
      {required String role,
      required String title,
      required String subtitle,
      required IconData icon}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5EC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFF1B6B3A)
                  : const Color(0xFFE2E8F0),
              width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon,
                  color: isSelected
                      ? const Color(0xFF1B6B3A)
                      : const Color(0xFFA0AEC0),
                  size: 24),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: Color(0xFF1B6B3A), size: 20),
            ]),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF2D3748))),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF718096))),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerForm(AuthState authState) {
    return Column(
      children: [
        // Nama Lengkap
        _buildTextField(
          controller: _nameController,
          hint: 'Masukkan nama lengkap Anda',
          label: 'NAMA LENGKAP',
        ),
        const SizedBox(height: 20),

        // Email
        _buildTextField(
          controller: _emailController,
          hint: 'contoh@email.com',
          label: 'EMAIL',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // Nomor HP
        _buildPhoneField(),
        const SizedBox(height: 20),

        // Password
        _buildPasswordField(
          controller: _passwordController,
          label: 'PASSWORD',
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 20),

        // Konfirmasi Password
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'KONFIRMASI PASSWORD',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 32),

        // Tombol Buat Akun
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F5A2F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: authState.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Buat Akun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),

        // Syarat
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            text: 'Dengan mendaftar, Anda menyetujui ',
            style: TextStyle(color: Color(0xFF718096), fontSize: 10),
            children: [
              TextSpan(
                text: 'Syarat &\nKetentuan',
                style: TextStyle(
                  color: Color(0xFF1B6B3A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' serta '),
              TextSpan(
                text: 'Kebijakan Privasi',
                style: TextStyle(
                  color: Color(0xFF1B6B3A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' LapangKu.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMitraForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar sebagai Pemilik',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Masukkan email atau nomor HP untuk mulai.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _MitraContactController,
          hint: 'contoh@email.com / 0812...',
          label: 'EMAIL ATAU NOMOR HP',
        ),
        const SizedBox(height: 65),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MitraRegisterPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F5A2F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Kirim Kode OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
