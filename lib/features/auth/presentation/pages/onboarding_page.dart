import 'package:flutter/material.dart';


class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Pesan dalam\nHitungan Menit',
      'subtitle': 'Pilih jadwal bermain, lakukan pembayaran,\ndan booking langsung dikonfirmasi',
      'icon': 'booking',
    },
    {
      'title': 'Temukan Lapangan\nTerbaik',
      'subtitle': 'Cari lapangan olahraga favoritmu di\ndekatmu dengan mudah dan cepat',
      'icon': 'field',
    },
    {
      'title': 'Pantau Semua\nPesananmu',
      'subtitle': 'Cek jadwal, riwayat booking, dan tiket\ndigital kapan saja dengan mudah',
      'icon': 'tracking',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09140D),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: 100,
            left: -50,
            right: -50,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B6B3A).withOpacity(0.5),
                    blurRadius: 120,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),

          // Stationary White Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
            ),
          ),

          // Content Layer
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        // Graphic Area
                        Expanded(
                          child: Center(
                            child: _buildIllustration(_slides[index]['icon']!),
                          ),
                        ),
                        // Text Area (Inside white sheet)
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 40.0,
                              left: 24.0,
                              right: 24.0,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _slides[index]['title']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A2128),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _slides[index]['subtitle']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF718096),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Stationary Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? const Color(0xFF1B6B3A)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6B3A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        _currentPage < _slides.length - 1
                            ? 'Selanjutnya'
                            : 'Mulai Sekarang →',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      'LEWATI',
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(String type) {
    switch (type) {
      case 'booking':
        return _buildBookingIllustration();
      case 'field':
        return _buildFieldIllustration();
      case 'tracking':
        return _buildTrackingIllustration();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBookingIllustration() {
    return Container(
      width: 240,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF5F56))),
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFBD2E))),
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF27C93F))),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.calendar_today_rounded, size: 48, color: Color(0xFF1B6B3A)),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF1B6B3A), size: 24),
                  const SizedBox(width: 8),
                  Container(width: 80, height: 6, decoration: BoxDecoration(color: const Color(0xFF1B6B3A).withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldIllustration() {
    return Container(
      width: 240,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF2C7A51),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 20,
            child: Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
            )
          ),
          const Icon(Icons.sports_basketball, size: 80, color: Colors.orange),
          const Positioned(
            left: 30,
            top: 50,
            child: Icon(Icons.sports_tennis, size: 40, color: Colors.white),
          ),
          const Positioned(
            right: 30,
            top: 80,
            child: Icon(Icons.sports_soccer, size: 60, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingIllustration() {
    return Container(
      width: 200,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF1A3626), width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                const Icon(Icons.menu, size: 16, color: Colors.black),
                const Spacer(),
                Container(width: 40, height: 12, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1B6B3A),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 60, height: 8, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lunas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                    ],
                  ),
                  const Spacer(),
                  Container(width: double.infinity, height: 8, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 8, color: Colors.white.withOpacity(0.2)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2, size: 60, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


