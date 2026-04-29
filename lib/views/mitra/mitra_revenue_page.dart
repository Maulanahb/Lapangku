import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MitraRevenuePage extends ConsumerStatefulWidget {
  const MitraRevenuePage({super.key});

  @override
  ConsumerState<MitraRevenuePage> createState() => _MitraRevenuePageState();
}

class _MitraRevenuePageState extends ConsumerState<MitraRevenuePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pendapatan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F5A3C),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monetization_on_outlined, size: 80, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text(
              'Ringkasan Pendapatan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
            SizedBox(height: 8),
            Text(
              'Halaman ini sedang dalam pengembangan.',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
