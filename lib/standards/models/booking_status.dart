import 'package:flutter/material.dart';
import 'package:lapangku/standards/constants/app_colors.dart';

// --- Enum ---
/// Status booking Lapangku — satu-satunya definisi yang ada di seluruh project.
enum BookingStatus {
  menungguBayar,
  menungguKonfirmasi,
  dikonfirmasi,
  aktif,
  selesai,
  dibatalkan,
  ditolak,
  expired,
  unknown,
}

// --- Extension ---
extension BookingStatusX on BookingStatus {
  // ── Label teks yang ditampilkan ke user ───────────────────────────────────
  String get label {
    switch (this) {
      case BookingStatus.menungguBayar:
        return 'Menunggu Pembayaran';
      case BookingStatus.menungguKonfirmasi:
        return 'Menunggu Konfirmasi';
      case BookingStatus.dikonfirmasi:
      case BookingStatus.aktif:
        return 'Aktif';
      case BookingStatus.selesai:
        return 'Selesai';
      case BookingStatus.dibatalkan:
        return 'Dibatalkan';
      case BookingStatus.ditolak:
        return 'Ditolak';
      case BookingStatus.expired:
        return 'Melewati Batas';
      case BookingStatus.unknown:
        return 'Tidak Diketahui';
    }
  }

  /// Label singkat untuk chip/badge (ALL CAPS)
  String get badgeLabel => label.toUpperCase();

  /// Label chip filter pendek (Sentence case)
  String get chipLabel {
    switch (this) {
      case BookingStatus.menungguBayar:
        return 'Menunggu Bayar';
      case BookingStatus.menungguKonfirmasi:
        return 'Menunggu';
      case BookingStatus.dikonfirmasi:
      case BookingStatus.aktif:
        return 'Dikonfirmasi';
      case BookingStatus.selesai:
        return 'Selesai';
      case BookingStatus.dibatalkan:
        return 'Dibatalkan';
      case BookingStatus.ditolak:
        return 'Ditolak';
      case BookingStatus.expired:
        return 'Melewati Batas';
      case BookingStatus.unknown:
        return 'Tidak Diketahui';
    }
  }

  // ── Warna foreground (teks / icon) ────────────────────────────────────────
  Color get color {
    switch (this) {
      case BookingStatus.menungguBayar:
        return AppColors.statusPending;
      case BookingStatus.menungguKonfirmasi:
        return AppColors.statusWaiting;
      case BookingStatus.dikonfirmasi:
      case BookingStatus.aktif:
        return AppColors.statusConfirmed;
      case BookingStatus.selesai:
        return AppColors.statusDone;
      case BookingStatus.dibatalkan:
      case BookingStatus.ditolak:
        return AppColors.statusCancelled;
      case BookingStatus.expired:
        return AppColors.textSecondary;
      case BookingStatus.unknown:
        return AppColors.textSecondary;
    }
  }

  // ── Warna background badge ────────────────────────────────────────────────
  Color get backgroundColor {
    switch (this) {
      case BookingStatus.menungguBayar:
        return AppColors.statusPendingBg;
      case BookingStatus.menungguKonfirmasi:
        return AppColors.statusWaitingBg;
      case BookingStatus.dikonfirmasi:
      case BookingStatus.aktif:
        return AppColors.statusConfirmedBg;
      case BookingStatus.selesai:
        return AppColors.statusDoneBg;
      case BookingStatus.dibatalkan:
      case BookingStatus.ditolak:
        return AppColors.statusCancelledBg;
      case BookingStatus.expired:
        return AppColors.backgroundChip;
      case BookingStatus.unknown:
        return AppColors.backgroundChip;
    }
  }

  // ── Warna background header halaman detail ────────────────────────────────
  Color get headerColor {
    switch (this) {
      case BookingStatus.menungguBayar:
        return Colors.orange.shade800;
      case BookingStatus.menungguKonfirmasi:
        return const Color(0xFF1A365D);
      case BookingStatus.dikonfirmasi:
      case BookingStatus.aktif:
        return AppColors.primary;
      case BookingStatus.selesai:
        return Colors.grey.shade700;
      case BookingStatus.dibatalkan:
      case BookingStatus.ditolak:
        return Colors.red.shade700;
      case BookingStatus.expired:
        return Colors.grey;
      case BookingStatus.unknown:
        return Colors.grey;
    }
  }

  // ── Label header halaman detail ───────────────────────────────────────────
  String get headerTitle {
    switch (this) {
      case BookingStatus.menungguBayar:
        return 'Menunggu Pembayaran';
      case BookingStatus.menungguKonfirmasi:
        return 'Menunggu Konfirmasi Pembayaran';
      case BookingStatus.dikonfirmasi:
      case BookingStatus.aktif:
        return 'Pesanan Dikonfirmasi';
      case BookingStatus.selesai:
        return 'Pesanan Selesai';
      case BookingStatus.dibatalkan:
        return 'Pesanan Dibatalkan';
      case BookingStatus.ditolak:
        return 'Pesanan Ditolak';
      case BookingStatus.expired:
        return 'Pesanan Melewati Batas';
      case BookingStatus.unknown:
        return 'Status Tidak Diketahui';
    }
  }

  // ── Icon ─────────────────────────────────────────────────────────────────
  IconData get icon {
    switch (this) {
      case BookingStatus.menungguBayar:
        return Icons.payment_outlined;
      case BookingStatus.menungguKonfirmasi:
        return Icons.hourglass_top_rounded;
      case BookingStatus.dikonfirmasi:
      case BookingStatus.aktif:
        return Icons.check_circle_outline;
      case BookingStatus.selesai:
        return Icons.task_alt;
      case BookingStatus.dibatalkan:
      case BookingStatus.ditolak:
        return Icons.cancel_outlined;
      case BookingStatus.expired:
        return Icons.timer_off_outlined;
      case BookingStatus.unknown:
        return Icons.help_outline;
    }
  }

  // ── Nilai string Firestore ────────────────────────────────────────────────
  String get firestoreValue {
    switch (this) {
      case BookingStatus.menungguBayar:
        return 'menunggu_bayar';
      case BookingStatus.menungguKonfirmasi:
        return 'menunggu_konfirmasi';
      case BookingStatus.dikonfirmasi:
        return 'dikonfirmasi';
      case BookingStatus.aktif:
        return 'aktif';
      case BookingStatus.selesai:
        return 'selesai';
      case BookingStatus.dibatalkan:
        return 'dibatalkan';
      case BookingStatus.ditolak:
        return 'ditolak';
      case BookingStatus.expired:
        return 'expired';
      case BookingStatus.unknown:
        return '';
    }
  }
}

// --- Factory ---
extension BookingStatusParsing on BookingStatus {
  /// Parse string dari Firestore ke enum BookingStatus.
  /// Dipanggil sebagai: BookingStatus.fromString('menunggu_bayar')
  static BookingStatus fromString(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'menunggu_bayar':
        return BookingStatus.menungguBayar;
      case 'menunggu_konfirmasi':
        return BookingStatus.menungguKonfirmasi;
      case 'dikonfirmasi':
        return BookingStatus.dikonfirmasi;
      case 'aktif':
        return BookingStatus.aktif;
      case 'selesai':
        return BookingStatus.selesai;
      case 'dibatalkan':
        return BookingStatus.dibatalkan;
      case 'ditolak':
        return BookingStatus.ditolak;
      case 'expired':
        return BookingStatus.expired;
      default:
        return BookingStatus.unknown;
    }
  }
}
