import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  static const _primary = Color(0xFF1B6B3A);
  static const _fieldBg = Color(0xFFEEF0F7);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _emailError;
  String? _passwordError;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('admin_remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('admin_email') ?? '';
        _passwordController.text = prefs.getString('admin_password') ?? '';
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _loginError = null;
    });

    if (_emailController.text.isEmpty && _passwordController.text.isEmpty) {
      setState(() {
        _emailError = 'Email tidak boleh kosong';
        _passwordError = 'Password tidak boleh kosong';
        _loginError = 'Email dan password tidak boleh kosong';
      });
      return;
    }
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email tidak boleh kosong';
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password tidak boleh kosong';
      });
      return;
    }

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (!mounted) return;

      final authState = ref.read(authProvider);

      if (authState.errorMessage != null) {
        setState(() {
          _emailError = '';
          _passwordError = '';
          _loginError = 'Email atau password yang kamu masukkan salah';
        });
        return;
      }

      if (authState.user != null) {
        if (authState.user!.role.toLowerCase() == 'admin') {
          final prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
            await prefs.setBool('admin_remember_me', true);
            await prefs.setString('admin_email', _emailController.text.trim());
            await prefs.setString(
                'admin_password', _passwordController.text.trim());
          } else {
            await prefs.remove('admin_remember_me');
            await prefs.remove('admin_email');
            await prefs.remove('admin_password');
          }

          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/admin-home');
        } else {
          setState(() {
            _loginError = 'Akun ini bukan admin!';
          });
          await ref.read(authProvider.notifier).logout();
        }
      }
    } catch (e) {
      ref.read(authProvider.notifier).setLoading(false);
      if (mounted) {
        setState(() {
          _loginError = 'Terjadi kesalahan: $e';
        });
        _showSnackbar('Terjadi kesalahan: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B6B3A),
                          ),
                        ),
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // â”€â”€â”€ Email Field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                const Text(
                  'Email Admin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => setState(() {
                    _emailError = null;
                    _loginError = null;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Masukkan email',
                    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: _emailError != null
                          ? Colors.red
                          : const Color(0xFF718096),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: _emailError != null
                        ? Colors.red.withOpacity(0.05)
                        : _fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: _emailError != null
                          ? const BorderSide(color: Colors.red, width: 1.5)
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emailError != null ? Colors.red : _primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (_emailError != null && _emailError!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 13, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        _emailError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // â”€â”€â”€ Password Field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => setState(() {
                    _passwordError = null;
                    _loginError = null;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Masukkan password',
                    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: _passwordError != null
                          ? Colors.red
                          : const Color(0xFF718096),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF718096),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: _passwordError != null
                        ? Colors.red.withOpacity(0.05)
                        : _fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: _passwordError != null
                          ? const BorderSide(color: Colors.red, width: 1.5)
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _passwordError != null ? Colors.red : _primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (_passwordError != null && _passwordError!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 13, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        _passwordError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // â”€â”€â”€ Remember Me & Lupa Password â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            activeColor: _primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                              color: Color(0xFFCBD5E0),
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ingat Saya',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_loginError != null && _loginError!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // â”€â”€â”€ Login Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Masuk ke Dashboard',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
