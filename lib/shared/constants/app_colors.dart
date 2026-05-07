import 'package:flutter/material.dart';

/// Satu-satunya sumber kebenaran untuk semua warna di aplikasi Lapangku.
/// JANGAN hardcode Color() di file lain — gunakan AppColors.xxx.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── PRIMARY BRAND ────────────────────────────────────────────────────────
  /// Hijau utama brand Lapangku — dipakai di AppBar, button, highlight
  static const Color primary = Color(0xFF1B6B3A);

  /// Varian gelap dari primary — untuk gradient header
  static const Color primaryDark = Color(0xFF114B27);

  /// Overlay/opacity ringan dari primary (untuk background icon/avatar)
  static const Color primaryLight = Color(0xFFE8F5EC);

  /// Overlay primary untuk card terpilih
  static const Color primarySelected = Color(0xFFD1FAE5);

  // ─── TEXT ─────────────────────────────────────────────────────────────────
  /// Teks judul/heading gelap
  static const Color textDark = Color(0xFF2D3748);

  /// Teks body/label sekunder
  static const Color textSecondary = Color(0xFF718096);

  /// Teks sangat gelap — hampir hitam, untuk heading utama
  static const Color textHeading = Color(0xFF1A1A2E);

  /// Teks hitam samar (label informasi)
  static const Color textBlackSoft = Color(0xFF1B4332);

  /// Warna badge teks biru tua (untuk label metode pembayaran)
  static const Color textBlueDark = Color(0xFF1A365D);

  // ─── BACKGROUND ───────────────────────────────────────────────────────────
  /// Background utama halaman — abu sangat muda
  static const Color backgroundPage = Color(0xFFF4F6F9);

  /// Background halaman alternatif
  static const Color backgroundPageAlt = Color(0xFFF9FAFB);

  /// Background input / container abu muda
  static const Color backgroundInput = Color(0xFFF0F2F5);

  /// Background input alternatif
  static const Color backgroundInputAlt = Color(0xFFF3F4F6);

  /// Background chip/badge netral
  static const Color backgroundChip = Color(0xFFF7F8FA);

  // ─── STATUS — BOOKING ─────────────────────────────────────────────────────
  /// Warna status "Menunggu Bayar" — oranye
  static const Color statusPending = Color(0xFFD97706);

  /// Background badge "Menunggu Bayar"
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  /// Teks badge "Menunggu Bayar"
  static const Color statusPendingText = Color(0xFF92400E);

  /// Warna status "Menunggu Konfirmasi" — biru
  static const Color statusWaiting = Color(0xFF2B6CB0);

  /// Background badge "Menunggu Konfirmasi"
  static const Color statusWaitingBg = Color(0xFFEBF8FF);

  /// Warna status "Dikonfirmasi / Aktif" — hijau brand
  static const Color statusConfirmed = primary;

  /// Background badge "Dikonfirmasi"
  static const Color statusConfirmedBg = primarySelected;

  /// Warna status "Selesai" — indigo
  static const Color statusDone = Color(0xFF4338CA);

  /// Background badge "Selesai"
  static const Color statusDoneBg = Color(0xFFE0E7FF);

  /// Warna status "Dibatalkan" — merah
  static const Color statusCancelled = Color(0xFFB91C1C);

  /// Background badge "Dibatalkan"
  static const Color statusCancelledBg = Color(0xFFFEE2E2);

  // ─── STATUS — FILTER (admin bookings) ────────────────────────────────────
  /// Warna status "Dikonfirmasi" di halaman admin (biru material)
  static const Color statusConfirmedAdmin = Color(0xFF2196F3);

  /// Warna status "Selesai" di halaman admin (hijau)
  static const Color statusDoneAdmin = Colors.green;

  // ─── UI ELEMENT ──────────────────────────────────────────────────────────
  /// Warna hint / placeholder pada TextField
  static const Color hint = Color(0xFFADB5BD);

  /// Garis pembatas halus
  static const Color divider = Color(0xFFE2E8F0);

  /// Border elemen ringan (sama dengan divider — alias untuk keterbacaan)
  static const Color borderLight = Color(0xFFE2E8F0);

  /// Shadow halus universal
  static const Color shadow = Color(0x0D000000); // black @ 5%

  // ─── TEXT BODY ────────────────────────────────────────────────────────────
  /// Teks body paragraf — abu gelap
  static const Color textBody = Color(0xFF4A5568);

  // ─── GREEN TINTED BACKGROUNDS ─────────────────────────────────────────────
  /// Background chip/card warna hijau sangat muda (fasilitas, info row)
  static const Color backgroundChipGreen = Color(0xFFF0FDF4);

  /// Border chip/card hijau muda (pelengkap backgroundChipGreen)
  static const Color primaryBorder = Color(0xFFBBF7D0);

  // ─── STATUS SUCCESS (alias) ───────────────────────────────────────────────
  /// Background badge status sukses/kategori (alias primarySelected)
  static const Color statusSuccessBg = primarySelected;

  // ─── SEMANTIC ─────────────────────────────────────────────────────────────
  /// Warna error / destruktif
  static const Color error = Colors.red;

  /// Warna amber / ulasan bintang
  static const Color star = Colors.amber;
}
