// Halaman Keamanan Mitra
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_security_controller.dart';
import 'package:lapangku/models/mitra/mitra_device_model.dart';
import 'package:lapangku/models/mitra/mitra_security_log_model.dart';
import 'package:lapangku/standards/constants/app_colors.dart';
import 'package:lapangku/standards/utils/date_formatter.dart';
import 'package:lapangku/standards/widgets/loading_overlay.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: security.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(mitraSecurityControllerProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  // Subheader
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  _SectionHeader(title: 'Login & Password'),
                  _SectionCard(children: [
                    // Ubah Password
                    _SecurityTile(
                      icon: Icons.password_rounded,
                      title: 'Ubah Password',
                      subtitle: security.lastPasswordChange != null
                          ? 'Terakhir diubah ${DateFormatter.relative(security.lastPasswordChange!)}'
                          : 'Belum pernah diubah',
                      trailing: _StatusChip(label: 'Aktif', color: AppColors.primary),
                      onTap: () => _navigateToChangePassword(context),
                    ),
                    _Divider(),

                    // PIN Keamanan
                    _PinTile(security: security),
                    _Divider(),

                    // Verifikasi Email
                    _EmailVerificationTile(security: security),
                  ]),

                  const SizedBox(height: 8),

                  // ── Section Perangkat Login ──
                  _SectionHeader(title: 'Perangkat Login'),
                  _DevicesSection(),

                  const SizedBox(height: 8),

                  // ── Section Aktivitas Keamanan ──
                  _SecurityLogsSection(),

                  const SizedBox(height: 8),

                  // ── Footer Peringatan ──
                  _SecurityWarningCard(),
                ],
              ),
            ),
    );
  }

  void _navigateToChangePassword(BuildContext context) {
    // Navigasi ke ChangePasswordPage yang sudah ada
    // dan setelah kembali, tandai password sudah diubah
    Navigator.pushNamed(context, '/mitra/change-password').then((_) {
      ref.read(mitraSecurityControllerProvider.notifier).markPasswordChanged();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const _SectionHeader({required this.title, this.action, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeading,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 56,
        endIndent: 16,
        color: AppColors.borderLight,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// GENERIC SECURITY TILE
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
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
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN TILE
// ─────────────────────────────────────────────────────────────────────────────

class _PinTile extends ConsumerWidget {
  final MitraSecurityState security;
  const _PinTile({required this.security});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 20),
      ),
      title: const Text(
        'PIN Keamanan',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textHeading),
      ),
      subtitle: const Text(
        'Untuk konfirmasi penarikan',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(
            label: security.pinEnabled ? 'Aktif' : 'Nonaktif',
            color: security.pinEnabled ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showPinDialog(context, ref, security.pinEnabled),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                security.pinEnabled ? 'Ubah' : 'Atur',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, WidgetRef ref, bool pinEnabled) {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          pinEnabled ? 'Ubah PIN Keamanan' : 'Atur PIN Keamanan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pinEnabled)
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      LoadingOverlay.show(context, message: 'Menonaktifkan PIN...');
                      await ref.read(mitraSecurityControllerProvider.notifier).togglePin(false);
                      if (context.mounted) {
                        LoadingOverlay.dismiss(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN berhasil dinonaktifkan')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        LoadingOverlay.dismiss(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.toggle_off, color: Colors.red),
                  label: const Text('Nonaktifkan PIN', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: 'Masukkan PIN baru (min. 6 digit)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return 'PIN minimal 6 digit';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                LoadingOverlay.show(context, message: 'Menyimpan PIN...');
                await ref
                    .read(mitraSecurityControllerProvider.notifier)
                    .setPin(pinController.text.trim());
                if (context.mounted) {
                  LoadingOverlay.dismiss(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN berhasil disimpan')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  LoadingOverlay.dismiss(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMAIL VERIFICATION TILE
// ─────────────────────────────────────────────────────────────────────────────

class _EmailVerificationTile extends ConsumerWidget {
  final MitraSecurityState security;
  const _EmailVerificationTile({required this.security});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verified = security.emailVerified;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
      ),
      title: Row(
        children: [
          const Text(
            'Verifikasi Email',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textHeading),
          ),
          if (verified) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified, color: AppColors.primary, size: 16),
          ],
        ],
      ),
      subtitle: Text(
        security.email.isEmpty ? 'Email tidak tersedia' : security.email,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: verified
          ? _StatusChip(label: 'Aktif', color: AppColors.primary)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(label: 'Belum Verifikasi', color: Colors.orange),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendVerification(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kirim Ulang',
                      style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _sendVerification(BuildContext context, WidgetRef ref) async {
    try {
      LoadingOverlay.show(context, message: 'Mengirim email verifikasi...');
      await ref.read(mitraSecurityControllerProvider.notifier).sendEmailVerification();
      if (context.mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verifikasi telah dikirim. Silakan cek inbox Anda.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.dismiss(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVICES SECTION (StreamBuilder)
// ─────────────────────────────────────────────────────────────────────────────

class _DevicesSection extends ConsumerWidget {
  const _DevicesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(mitraSecurityControllerProvider.notifier).watchDevices();

    return StreamBuilder<List<MitraDeviceModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final devices = snapshot.data ?? [];

        if (devices.isEmpty) {
          return _SectionCard(children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Belum ada perangkat yang terdaftar',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          ]);
        }

        return _SectionCard(
          children: List.generate(devices.length * 2 - 1, (i) {
            if (i.isOdd) return _Divider();
            final device = devices[i ~/ 2];
            return _DeviceTile(device: device);
          }),
        );
      },
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  final MitraDeviceModel device;
  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = device.isCurrentDevice ||
        DateTime.now().difference(device.lastActive).inMinutes < 5;

    IconData deviceIcon;
    switch (device.deviceType.toLowerCase()) {
      case 'ios':
        deviceIcon = Icons.phone_iphone;
        break;
      case 'web':
        deviceIcon = Icons.computer;
        break;
      default:
        deviceIcon = Icons.phone_android;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(deviceIcon, color: AppColors.textSecondary, size: 20),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              device.deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
          if (device.isCurrentDevice) ...[
            const SizedBox(width: 6),
            _StatusChip(label: 'Perangkat Ini', color: AppColors.primary),
          ],
        ],
      ),
      subtitle: Text(
        device.isCurrentDevice
            ? '${device.location}, Aktif sekarang'
            : '${device.location}, ${DateFormatter.relative(device.lastActive)}',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: device.isCurrentDevice
          ? null
          : TextButton(
              onPressed: () => _confirmLogout(context, ref, device),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, MitraDeviceModel device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluarkan Perangkat?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin mengeluarkan ${device.deviceName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                LoadingOverlay.show(context, message: 'Mengeluarkan perangkat...');
                await ref
                    .read(mitraSecurityControllerProvider.notifier)
                    .logoutDevice(device.id, device.deviceName);
                if (context.mounted) {
                  LoadingOverlay.dismiss(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${device.deviceName} berhasil dikeluarkan')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  LoadingOverlay.dismiss(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECURITY LOGS SECTION (StreamBuilder)
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityLogsSection extends ConsumerWidget {
  const _SecurityLogsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream =
        ref.watch(mitraSecurityControllerProvider.notifier).watchSecurityLogs(limit: 10);

    return StreamBuilder<List<MitraSecurityLogModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];

        return Column(
          children: [
            _SectionHeader(
              title: 'Aktivitas Keamanan',
              action: logs.isNotEmpty ? 'Lihat Semua' : null,
            ),
            if (logs.isEmpty)
              _SectionCard(children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Belum ada aktivitas keamanan',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              ])
            else
              _SectionCard(
                children: List.generate(logs.length * 2 - 1, (i) {
                  if (i.isOdd) return _Divider();
                  return _LogTile(log: logs[i ~/ 2]);
                }),
              ),
          ],
        );
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  final MitraSecurityLogModel log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: log.type.bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(log.type.icon, color: log.type.color, size: 20),
      ),
      title: Text(
        log.type.label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.details.isNotEmpty)
            Text(log.details, style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
          Text(
            _formatLogTime(log.timestamp),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatLogTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return 'Hari ini, ${DateFormatter.time(dt)} WIB';
    } else if (diff.inDays == 1) {
      return 'Kemarin, ${DateFormatter.time(dt)} WIB';
    }
    return '${DateFormatter.short(dt)}, ${DateFormatter.time(dt)} WIB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER: PERINGATAN KEAMANAN
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityWarningCard extends StatelessWidget {
  const _SecurityWarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jaga Kerahasiaan Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pihak LapangKu tidak pernah meminta Password, PIN, atau kode OTP Anda. '
                  'Jangan berikan informasi tersebut kepada siapapun.',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFD97706),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
