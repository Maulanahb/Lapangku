import 'package:intl/intl.dart';

class DateFormatter {
  /// DateFormatter.full(date) → "Selasa, 12 Januari 2024"
  static String full(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  /// DateFormatter.short(date) → "12 Jan 2024"
  static String short(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  /// DateFormatter.time(date) → "14:30"
  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// DateFormatter.datetime(date) → "12 Jan 2024, 14:30"
  static String datetime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }

  /// DateFormatter.relative(date) → "2 jam lalu" / "kemarin"
  static String relative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 1) {
      return short(date);
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
