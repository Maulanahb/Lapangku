// Halaman Keamanan Mitra (Hanya Ubah Password)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_security_controller.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/date_formatter.dart';
import 'mitra_change_password_page.dart';

class MitraSecurityPage extends ConsumerStatefulWidget {
  const MitraSecurityPage({super.key});

  @override
  ConsumerState<MitraSecurityPage> createState() => _MitraSecurityPageState();
}

class _MitraSecurityPageState extends ConsumerState<MitraSecurityPage> {
  @override
  Widget build(BuildContext context) {
    final security = ref.watch(mitraSecurityControllerProvider);

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
          'Keamanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: security.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(mitraSecurityControllerProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  // Subheader
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Proteksi akun & akses login',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // ── Section Login & Password ──
                  const _SectionHeader(title: 'Login & Password'),
                  _SectionCard(
                    children: [
                      // Ubah Password
                      _SecurityTile(
                        icon: Icons.password_rounded,
                        title: 'Ubah Password',
                        subtitle: security.lastPasswordChange != null
                            ? 'Terakhir diubah ${DateFormatter.relative(security.lastPasswordChange!)}'
                            : 'Belum pernah diubah',
                        onTap: () => _navigateToChangePassword(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // 👇 INI BAGIAN YANG DIPERBAIKI AGAR BISA DI-KLIK 👇
  void _navigateToChangePassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MitraChangePasswordPage(),
      ),
    ).then((_) {
      // Refresh UI ketika kembali ke halaman ini agar waktunya terupdate
      ref.read(mitraSecurityControllerProvider.notifier).refresh();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET HELPERS (Dipertahankan hanya yang diperlukan)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textHeading,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.textHeading,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}
