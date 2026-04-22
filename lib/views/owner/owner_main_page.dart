import 'package:flutter/material.dart';
import 'owner_home_page.dart';
import 'manage_fields_page.dart';

class OwnerMainPage extends StatefulWidget {
  const OwnerMainPage({super.key});

  @override
  State<OwnerMainPage> createState() => _OwnerMainPageState();
}

class _OwnerMainPageState extends State<OwnerMainPage> {
  int _currentIndex = 0;
  final Color _primaryGreen = const Color(0xFF0F5A3C);

  final List<Widget> _pages = [
    const OwnerHomePage(key: ValueKey('home')),
    const ManageFieldsPage(key: ValueKey('fields')),
    const Center(key: ValueKey('orders'), child: Text('Halaman Orders (Belum Ada)')),
    const Center(key: ValueKey('profile'), child: Text('Halaman Profile (Belum Ada)')),
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
      padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10, top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view_rounded, 'DASHBOARD', 0),
          _buildNavItem(Icons.stadium_rounded, 'FIELDS', 1),
          _buildNavItem(Icons.assignment_outlined, 'ORDERS', 2),
          _buildNavItem(Icons.person_outline_rounded, 'PROFILE', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD1FAE5).withOpacity(0.5) : Colors.transparent,
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
