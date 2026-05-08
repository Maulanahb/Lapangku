import 'package:intl/intl.dart';

/// Satu-satunya fungsi format mata uang di seluruh project Lapangku.
/// Selalu gunakan fungsi ini — JANGAN tulis ulang format Rupiah di file lain.
class CurrencyFormatter {
  CurrencyFormatter._(); // Prevent instantiation

  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka menjadi "Rp 50.000"
  /// Contoh: formatCurrency(50000) → "Rp 50.000"
  static String format(int amount) => _formatter.format(amount);

  /// Format singkat untuk tampilan card/badge kecil.
  /// Contoh: formatShort(1500000) → "1,5jt"
  ///         formatShort(50000)   → "50rb"
  ///         formatShort(500)     → "Rp 500"
  static String formatShort(int amount) {
    if (amount >= 1000000) {
      final inMillions = amount / 1000000;
      return '${inMillions.toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}jt';
    }
    if (amount >= 1000) {
      final inThousands = amount / 1000;
      return '${inThousands.toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}rb';
    }
    return format(amount);
  }
}
