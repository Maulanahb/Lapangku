import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _emailSent = false;
  String _sentEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    
    // Validasi kosong
    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email wajib diisi')),
      );
      return;
    }

    // Validasi Regex Email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid. Periksa kembali email Anda.')),
      );
      return;
    }

    // Call Controller
    await ref.read(authProvider.notifier).sendPasswordReset(email);

    if (!mounted) return;
    
    final authState = ref.read(authProvider);

    // Tangani Error Firebase Exception
    if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.errorMessage!)),
      );
      return;
    }

    setState(() {
      _sentEmail = email;
      _emailSent = true;
    });
    _emailController.clear(); 
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF2D3748), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lupa Kata Sandi',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emailSent ? _buildSuccessState() : _buildFormState(authState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFE8F5EC), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.lock_reset, color: Color(0xFF1B6B3A), size: 40),
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: Text('Lupa Password?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))),
        const SizedBox(height: 12),
        const Center(
          child: Text('Masukkan emailmu dan kami kirimkan link\nreset password untuk mengamankan\nakunmu kembali.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF718096), height: 1.6)),
        ),
        const SizedBox(height: 40),
        const Text('EMAIL KAMU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF718096), letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'nama@email.com',
            hintStyle: const TextStyle(color: Color(0xFF718096)),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF718096), size: 20),
            filled: true, fillColor: const Color(0xFFF7F8FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : _sendReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6B3A), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: const Color(0xFF1B6B3A).withOpacity(0.6),
            ),
            child: authState.isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text('Kirim Link Reset →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF1B6B3A)),
            label: const Text('Kembali ke Login', style: TextStyle(color: Color(0xFF1B6B3A), fontWeight: FontWeight.bold)),
          ),
        ),
        const Spacer(),
        Center(child: Text('Butuh bantuan lebih lanjut? Hubungi Support', style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: const Color(0xFFE8F5EC), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF1B6B3A), size: 40),
        ),
        const SizedBox(height: 24),
        const Text('Email Terkirim!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF718096), height: 1.6),
            children: [
              const TextSpan(text: 'Link reset password telah dikirim ke email\n'),
              TextSpan(text: '$_sentEmail\n\n', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              const TextSpan(text: 'Silakan cek kotak masuk atau folder spam di aplikasi Email Anda, lalu klik link tersebut untuk membuat password baru.'),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6B3A), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kembali ke Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
