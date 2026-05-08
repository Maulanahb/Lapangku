import 'package:flutter/material.dart';
import 'package:lapangku/standards/constants/app_colors.dart';

/// Loading overlay reusable — menggantikan semua pola
/// showDialog(Center(CircularProgressIndicator())) yang tersebar.
///
/// Penggunaan (show + dismiss):
/// ```dart
/// LoadingOverlay.show(context, message: 'Menyimpan...');
/// // ... proses async ...
/// LoadingOverlay.dismiss(context);
/// ```
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  /// Tampilkan loading overlay di atas layar.
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingOverlay(message: message),
    );
  }

  /// Tutup loading overlay.
  static void dismiss(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: message != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
