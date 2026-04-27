import 'package:flutter/material.dart';

class Step5Photos extends StatelessWidget {
  const Step5Photos({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Foto Lapangan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Tampilkan kondisi terbaik lapangan kamu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEDF2F7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Galeri Foto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Minimal 2 foto',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF38A169),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Photo Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  // Contoh foto yang sudah ada (Placeholder)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A202C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.sports_soccer,
                          color: Colors.white24, size: 40),
                    ),
                  ),
                  // Tombol Tambah Foto
                  _buildPhotoSlot(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            color: Color(0xFF1B6B3A), size: 28),
                        const SizedBox(height: 8),
                        const Text(
                          'Tambah Foto',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // Slot kosong
                  _buildPhotoSlot(
                      child: const Icon(Icons.add, color: Color(0xFF1B6B3A))),
                  _buildPhotoSlot(
                      child: const Icon(Icons.add, color: Color(0xFF1B6B3A))),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Format: JPG, PNG. Maks 5MB per foto.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA0AEC0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPhotoSlot({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(child: child),
    );
  }
}
