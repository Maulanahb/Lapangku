import 'package:flutter/material.dart';
import 'dart:io';

class Step8Review extends StatelessWidget {
  final String ownerName;
  final String businessName;
  final String email;
  final String contact;
  final String fieldName;
  final String fieldDescription;
  final String address;
  final String price;
  final File? ktpPhoto;
  final File? selfiePhoto;
  final List<File> fieldPhotos;
  final Function(int) onEditStep;

  const Step8Review({
    super.key,
    required this.ownerName,
    required this.businessName,
    required this.email,
    required this.contact,
    required this.fieldName,
    required this.fieldDescription,
    required this.address,
    required this.price,
    required this.ktpPhoto,
    required this.selfiePhoto,
    required this.fieldPhotos,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B6B3A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Periksa Data',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B6B3A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pastikan semua data sudah benar sebelum mengirimkan pendaftaran.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Identitas
              _buildReviewSection(
                title: 'Identitas',
                onEdit: () => onEditStep(2),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pemilik: $ownerName',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4A5568))),
                    Text('Bisnis: $businessName',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4A5568))),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4A5568))),
                    Text(contact,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4A5568))),
                  ],
                ),
              ),
              const Divider(height: 48, color: Color(0xFFF1F5F9)),

              // Data Lapangan
              _buildReviewSection(
                title: 'Data Lapangan',
                onEdit: () => onEditStep(4),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fieldName,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4A5568))),
                    Text(fieldDescription,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4A5568))),
                  ],
                ),
              ),
              const Divider(height: 48, color: Color(0xFFF1F5F9)),

              // Lokasi
              _buildReviewSection(
                title: 'Lokasi',
                onEdit: () => onEditStep(5),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF4A5568))),
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Icon(Icons.map_outlined,
                              color: Color(0xFF94A3B8), size: 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 48, color: Color(0xFFF1F5F9)),

              // Foto
              _buildReviewSection(
                title: 'Foto',
                onEdit: () => onEditStep(6),
                content: SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fieldPhotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(fieldPhotos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 48, color: Color(0xFFF1F5F9)),

              // Harga
              _buildReviewSection(
                title: 'Harga',
                onEdit: () => onEditStep(7),
                content: Text(
                  'Mulai dari Rp $price / jam',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildReviewSection({
    required String title,
    required VoidCallback onEdit,
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
                const Icon(Icons.check_circle,
                    color: Color(0xFF1B6B3A), size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onEdit,
              child: const Text(
                'Ubah',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B6B3A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: content,
        ),
      ],
    );
  }
}
