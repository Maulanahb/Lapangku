import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/standards/widgets/empty_state_widget.dart';
import 'package:lapangku/views/customer/change_password_page.dart';
import 'package:lapangku/views/customer/widgets/otp_verification_sheet.dart';

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  String _deviceName = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String name = 'Tidak diketahui';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.utsname.machine; // machine name like iPhone13,4
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        name = windowsInfo.computerName;
      }
      if (mounted) setState(() => _deviceName = name);
    } catch (e) {
      if (mounted) setState(() => _deviceName = 'Gagal memuat info');
    }
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Belum pernah diubah';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} hari lalu';
    } else {
      return 'Hari ini';
    }
  }



  Future<void> _handleSendEmailVerification() async {
    LoadingOverlay.show(context, message: 'Mengirim email...');
    try {
      await ref.read(authProvider.notifier).sendEmailVerification();
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verifikasi telah dikirim. Silakan cek inbox Anda.')),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim email: $e')),
        );
      }
    }
  }

  void _showOTPVerificationSheet(UserModel user, String verificationId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => OTPVerificationSheet(
        phoneNumber: user.phone!,
        onVerify: (otpCode) async {
          Navigator.pop(sheetCtx); // Tutup sheet
          LoadingOverlay.show(context, message: 'Memverifikasi OTP...');
          try {
            await ref.read(authProvider.notifier).verifyPhoneOTP(verificationId, otpCode);
            if (mounted) {
              LoadingOverlay.dismiss(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nomor HP berhasil diverifikasi!')),
              );
            }
          } catch (e) {
            if (mounted) {
              LoadingOverlay.dismiss(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Verifikasi gagal: $e')),
              );
            }
          }
        },
        onResend: () {
          _handlePhoneVerification(user, resend: true);
        },
      ),
    );
  }

  Future<void> _handlePhoneVerification(UserModel user, {bool resend = false}) async {
    if (user.phone == null || user.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor HP belum diatur. Harap perbarui Profil Anda.')),
      );
      return;
    }

    if (!resend) LoadingOverlay.show(context, message: 'Mengirim OTP...');
    
    await ref.read(authProvider.notifier).sendPhoneVerificationOTP(
      phoneNumber: user.phone!,
      onCodeSent: (verificationId) {
        if (!resend && mounted) LoadingOverlay.dismiss(context);
        if (mounted) {
          if (resend) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP dikirim ulang')));
          } else {
            _showOTPVerificationSheet(user, verificationId);
          }
        }
      },
      onError: (e) {
        if (!resend && mounted) LoadingOverlay.dismiss(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim OTP: $e')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text(
          'Keamanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Gagal Memuat Data',
          subtitle: err.toString(),
          actionButton: ElevatedButton(
            onPressed: () => ref.invalidate(authStateProvider),
            child: const Text('Coba Lagi'),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const EmptyStateWidget(
              icon: Icons.person_off_outlined,
              title: 'Data tidak ditemukan',
              subtitle: 'Silakan login kembali.',
            );
          }
          return _buildContent(context, user);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HERO SECTION
          Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Akun Kamu Aman',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kelola keamanan akun dan lindungi data pribadimu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // SECTION 1 — PASSWORD
          _buildSectionTitle('Password'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ubah password akun secara berkala untuk menjaga keamanan akun kamu.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  'Terakhir diubah ${_getTimeAgo(user.lastPasswordChange)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Ubah Password',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SECTION 2 — VERIFIKASI AKUN
          _buildSectionTitle('Verifikasi Akun'),
          _buildCard(
            child: Column(
              children: [
                _buildVerificationRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                  isVerified: user.emailVerified,
                  onAction: user.emailVerified ? null : _handleSendEmailVerification,
                  actionText: 'Kirim Ulang',
                ),
                const Divider(height: 24),
                _buildVerificationRow(
                  icon: Icons.phone_android_outlined,
                  label: 'Nomor HP',
                  value: user.phone ?? '-',
                  isVerified: user.phoneVerified,
                  onAction: user.phoneVerified ? null : () => _handlePhoneVerification(user),
                  actionText: 'Verifikasi',
                ),
              ],
            ),
          ),



          const SizedBox(height: 24),

          // SECTION 4 — PERANGKAT LOGIN
          _buildSectionTitle('Perangkat Login'),
          _buildCard(
            child: Column(
              children: [
                _buildDeviceRow(
                  icon: Platform.isAndroid ? Icons.phone_android : (Platform.isIOS ? Icons.phone_iphone : Icons.laptop),
                  name: _deviceName,
                  location: user.city ?? 'Lokasi tidak diketahui',
                  isCurrent: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textHeading,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildVerificationRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isVerified,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
        if (isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 12),
                SizedBox(width: 4),
                Text(
                  'Terverifikasi',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Belum Verifikasi',
                  style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionText ?? 'Verifikasi',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDeviceRow({
    required IconData icon,
    required String name,
    required String location,
    bool isCurrent = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Aktif sekarang',
                        style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                location,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        if (isCurrent)
          const Text(
            'Perangkat Ini',
            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
