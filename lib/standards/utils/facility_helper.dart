import 'package:flutter/material.dart';

class FacilityHelper {
  static IconData getIcon(String facility) {
    final f = facility.toLowerCase();
    if (f.contains('parkir')) return Icons.local_parking;
    if (f.contains('toilet') || f.contains('kamar mandi') || f.contains('wc')) return Icons.wc;
    if (f.contains('mushola') || f.contains('masjid') || f.contains('sholat')) return Icons.mosque;
    if (f.contains('kantin') || f.contains('makan') || f.contains('cafe') || f.contains('minum')) return Icons.restaurant;
    if (f.contains('wifi') || f.contains('internet')) return Icons.wifi;
    if (f.contains('loker') || f.contains('locker')) return Icons.door_sliding;
    if (f.contains('ruang ganti') || f.contains('ganti')) return Icons.checkroom;
    if (f.contains('tribun') || f.contains('penonton') || f.contains('kursi')) return Icons.stadium;
    if (f.contains('ac') || f.contains('pendingin')) return Icons.ac_unit;
    if (f.contains('bola') || f.contains('sewa bola')) return Icons.sports_soccer_outlined; // Diubah sedikit agar lebih relevan dengan bola
    if (f.contains('p3k') || f.contains('medis') || f.contains('kesehatan')) return Icons.medical_services;
    return Icons.check_circle_outline;
  }
}
