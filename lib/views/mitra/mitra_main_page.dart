import 'package:flutter/material.dart';
import 'mitra_home_page.dart';
import 'manage_fields_page.dart';
import 'mitra_profile_page.dart';
import 'mitra_booking_list_page.dart';
import 'mitra_qr_scanner_page.dart';

class MitraMainPage extends StatefulWidget {
  const MitraMainPage({super.key});

  @override
  State<MitraMainPage> createState() => _MitraMainPageState();
}

class _MitraMainPageState extends State<MitraMainPage> {
  int _currentIndex = 0;
  final Color _primaryGreen = const Color(0xFF0F5A3C);

  final List<Widget> _pages = [
    const MitraHomePage(key: ValueKey('home')),
    const ManageFieldsPage(key: ValueKey('fields')),
    const MitraBookingListPage(key: ValueKey('orders')),
    const MitraProfilePage(key: ValueKey('profile')),
  ];

  void _onNavTapped(int index) {
    setState(() { _currentIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 6, right: 6, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view_rounded, 'DASHBOARD', 0),
          _buildNavItem(Icons.stadium_rounded, 'FIELDS', 1),
          _buildScanButton(),
          _buildNavItem(Icons.assignment_outlined, 'ORDERS', 2),
          _buildNavItem(Icons.person_outline_rounded, 'PROFILE', 3),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MitraQrScannerPage()),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text('SCAN', style: TextStyle(
            color: _primaryGreen,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          )),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD1FAE5).withValues(alpha: 0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? _primaryGreen : Colors.grey[400], size: 24),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: isActive ? _primaryGreen : Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
