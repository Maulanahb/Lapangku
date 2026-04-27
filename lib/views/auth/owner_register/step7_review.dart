import 'package:flutter/material.dart';
import 'widgets/map_placeholder.dart';

class Step7Review extends StatelessWidget {
  final String contact;
  final String fieldName;
  final String fieldDescription;
  final String address;
  final String price;
  final Function(int) onEditStep;

  const Step7Review({
    super.key,
    required this.contact,
    required this.fieldName,
    required this.fieldDescription,
    required this.address,
    required this.price,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Periksa Data',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A202C),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Pastikan semua data sudah benar sebelum mengirimkan pendaftaran.',
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
              // Identitas
              _buildReviewItem(
                step: 2,
                icon: Icons.check_circle,
                title: 'Identitas',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Budi Santoso',
                        style: TextStyle(color: Color(0xFF4A5568))),
                    const Text('budi.santoso@email.com',
                        style: TextStyle(color: Color(0xFF4A5568))),
                    Text(contact.isEmpty ? '081234567890' : contact),
                  ],
                ),
              ),
              const Divider(height: 32),

              // Data Lapangan
              _buildReviewItem(
                step: 3,
                icon: Icons.check_circle,
                title: 'Data Lapangan',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fieldName.isEmpty ? 'Futsal Kemerdekaan' : fieldName),
                    Text(fieldDescription.isEmpty
                        ? '2 Lapangan Sintetis, 1 Vinyl'
                        : fieldDescription),
                  ],
                ),
              ),
              const Divider(height: 32),

              // Lokasi
              _buildReviewItem(
                step: 4,
                icon: Icons.check_circle,
                title: 'Lokasi',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address.isEmpty
                        ? 'Jl. Pahlawan No. 45, Jakarta Selatan'
                        : address),
                    const SizedBox(height: 12),
                    const SizedBox(
                      height: 100,
                      child: MapPlaceholder(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),

              // Foto
              _buildReviewItem(
                step: 5,
                icon: Icons.check_circle,
                title: 'Foto',
                content: Row(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFE2E8F0),
                        ),
                        child: const Icon(Icons.image,
                            color: Color(0xFFA0AEC0), size: 24),
                      ),
                  ],
                ),
              ),
              const Divider(height: 32),

              // Harga
              _buildReviewItem(
                step: 6,
                icon: Icons.check_circle,
                title: 'Harga',
                content: Text(
                  'Mulai dari Rp ${price.isEmpty ? '100.000' : price} / jam',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildReviewItem({
    required int step,
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1B6B3A), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => onEditStep(step),
              child: const Text(
                'Ubah',
                style: TextStyle(
                    color: Color(0xFF38A169), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: content,
        ),
      ],
    );
  }
}
