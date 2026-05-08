import 'package:flutter/material.dart';
import 'package:lapangku/standards/constants/app_colors.dart';

/// Dialog konfirmasi reusable — menggantikan semua showDialog(AlertDialog)
/// yang ditulis ulang di berbagai halaman.
///
/// Penggunaan:
/// ```dart
/// final confirm = await ConfirmationDialog.show(
///   context: context,
///   title: 'Batalkan Pesanan?',
///   message: 'Apakah Anda yakin?',
///   confirmText: 'Ya, Batalkan',
///   isDestructive: true,
/// );
/// if (confirm == true) { /* lanjutkan aksi */ }
/// ```
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Ya',
    this.cancelText = 'Batal',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  /// Tampilkan dialog dan kembalikan `true` jika user menekan tombol konfirmasi.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: onConfirm != null ? () { onConfirm(); Navigator.pop(ctx, true); } : null,
        onCancel: onCancel != null ? () { onCancel(); Navigator.pop(ctx, false); } : null,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () {
            if (onCancel != null) {
              onCancel!();
            } else {
              Navigator.pop(context, false);
            }
          },
          child: Text(
            cancelText,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            if (onConfirm != null) {
              onConfirm!();
            } else {
              Navigator.pop(context, true);
            }
          },
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDestructive ? AppColors.error : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
