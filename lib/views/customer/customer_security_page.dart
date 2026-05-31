import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/controllers/customer/customer_security_controller.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';
import 'package:lapangku/views/customer/change_password_page.dart';
import 'package:lapangku/views/customer/widgets/phone_verification_dialog.dart';

class CustomerSecurityPage extends ConsumerStatefulWidget {
  const CustomerSecurityPage({super.key});

  @override
  ConsumerState<CustomerSecurityPage> createState() =>
      _CustomerSecurityPageState();
}

class _CustomerSecurityPageState extends ConsumerState<CustomerSecurityPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(customerSecurityControllerProvider.notifier)
          .refreshEmailVerificationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    ref.listen<AsyncValue<void>>(
      customerSecurityControllerProvider,
      (previous, next) {
        if (next.isLoading) {
          LoadingOverlay.show(context, message: 'Memproses...');
        } else if (previous?.isLoading == true) {
          LoadingOverlay.dismiss(context);
          if (next.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(next.error.toString())),
            );
          }
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppColors.primary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Keamanan',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(customerSecurityControllerProvider.notifier)
                  .refreshEmailVerificationStatus();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildHeroSection(),
                  _buildPasswordSection(context, user),
                  _buildVerifikasiAkunSection(context, user),
                  _buildPerangkatLoginSection(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.backgroundChipGreen,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.security, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Akun Kamu Aman',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading)),
          const SizedBox(height: 8),
          const Text('Kelola keamanan akun dan lindungi data pribadimu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(BuildContext context, UserModel user) {
    String lastChangedText = 'Belum pernah diubah';
    if (user.lastPasswordChange != null) {
      final diff = DateTime.now().difference(user.lastPasswordChange!);
      if (diff.inDays > 30)
        lastChangedText = 'Terakhir diubah ${diff.inDays ~/ 30} bulan lalu';
      else if (diff.inDays > 0)
        lastChangedText = 'Terakhir diubah ${diff.inDays} hari lalu';
      else
        lastChangedText = 'Terakhir diubah hari ini';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: AppColors.backgroundField, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline,
                      color: AppColors.textBody, size: 20)),
              const SizedBox(width: 16),
              const Text('Password',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
              'Ubah password akun secara berkala untuk menjaga keamanan akun kamu.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
          const Divider(color: AppColors.divider, thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lastChangedText,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordPage())),
                child: const Text('Ubah Password',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifikasiAkunSection(BuildContext context, UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verifikasi Akun',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading)),
          const SizedBox(height: 20),
          _buildEmailItem(user),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, thickness: 1),
          const SizedBox(height: 16),
          _buildPhoneItem(context, user),
        ],
      ),
    );
  }

  Widget _buildEmailItem(UserModel user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: AppColors.backgroundField, shape: BoxShape.circle),
            child: const Icon(Icons.email_outlined,
                color: AppColors.textBody, size: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(user.email,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textHeading)),
              const SizedBox(height: 8),
              _buildBadge(user.emailVerified),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneItem(BuildContext context, UserModel user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: AppColors.backgroundField, shape: BoxShape.circle),
            child: const Icon(Icons.phone_android,
                color: AppColors.textBody, size: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nomor HP',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                  user.phone != null && user.phone!.isNotEmpty
                      ? user.phone!
                      : 'Belum ditambahkan',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textHeading)),
              const SizedBox(height: 8),
              _buildBadge(user.phoneVerified),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: isVerified
              ? AppColors.statusSuccessBg
              : AppColors.statusPendingBg,
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.check_circle_outline : Icons.error_outline,
              size: 14,
              color:
                  isVerified ? AppColors.primary : AppColors.statusPendingText),
          const SizedBox(width: 4),
          Text(isVerified ? 'Terverifikasi' : 'Belum Verifikasi',
              style: TextStyle(
                  fontSize: 11,
                  color: isVerified
                      ? AppColors.primary
                      : AppColors.statusPendingText)),
        ],
      ),
    );
  }

  Widget _buildPerangkatLoginSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perangkat Login',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading)),
          const SizedBox(height: 20),
          // StreamBuilder logic tetap di sini...
        ],
      ),
    );
  }
}
