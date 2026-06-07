import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_security_controller.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';

class MitraChangePasswordPage extends ConsumerStatefulWidget {
  const MitraChangePasswordPage({super.key});

  @override
  ConsumerState<MitraChangePasswordPage> createState() =>
      _MitraChangePasswordPageState();
}

class _MitraChangePasswordPageState
    extends ConsumerState<MitraChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Tutup keyboard
    FocusScope.of(context).unfocus();

    try {
      LoadingOverlay.show(context, message: 'Memperbarui password...');

      await ref.read(mitraSecurityControllerProvider.notifier).changePassword(
            _oldPasswordCtrl.text.trim(),
            _newPasswordCtrl.text.trim(),
          );

      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diperbarui!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating, // UX: SnackBar melayang
          ),
        );
        Navigator.pop(
            context, true); // Kembali ke halaman sebelumnya bawa flag true
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ubah Password',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Area Form ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ILLUSTRATION ---
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- TEKS JUDUL ---
                    const Center(
                      child: Text(
                        'Buat Password Baru',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeading),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Pastikan password baru Anda unik, aman,\ndan berbeda dari password sebelumnya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- PASSWORD LAMA ---
                    _buildPasswordField(
                      label: 'Password Lama',
                      controller: _oldPasswordCtrl,
                      obscureText: _obscureOld,
                      onToggleObscure: () =>
                          setState(() => _obscureOld = !_obscureOld),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Password lama tidak boleh kosong';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- PASSWORD BARU ---
                    _buildPasswordField(
                      label: 'Password Baru',
                      controller: _newPasswordCtrl,
                      obscureText: _obscureNew,
                      onToggleObscure: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Password baru tidak boleh kosong';
                        if (val.length < 6)
                          return 'Password minimal 6 karakter';
                        if (val == _oldPasswordCtrl.text)
                          return 'Password baru tidak boleh sama dengan yang lama';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- KONFIRMASI PASSWORD BARU ---
                    _buildPasswordField(
                      label: 'Konfirmasi Password Baru',
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      isLastField: true, // Untuk mengatur action keyboard
                      onToggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Konfirmasi password tidak boleh kosong';
                        if (val != _newPasswordCtrl.text)
                          return 'Password konfirmasi tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Area Tombol Simpan ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4), // Shadow mengarah ke atas
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Password',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    bool isLastField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction:
              isLastField ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: isLastField ? (_) => _submitChangePassword() : null,
          style: const TextStyle(fontSize: 14, color: AppColors.textHeading),
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppColors.textSecondary, size: 22),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggleObscure,
              splashRadius: 24,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
