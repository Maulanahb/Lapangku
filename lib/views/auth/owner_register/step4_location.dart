import 'package:flutter/material.dart';
import 'widgets/map_placeholder.dart';

class Step4Location extends StatelessWidget {
  final TextEditingController addressController;

  const Step4Location({
    super.key,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Temukan Lokasi',
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
            'Pastikan lokasi akurat agar mudah ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
        ),
        const SizedBox(height: 32),

        const MapPlaceholder(),

        const SizedBox(height: 16),

        // Gunakan lokasi saya button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.my_location, size: 20),
            label: const Text('Gunakan lokasi saya'),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFF1B6B3A),
              backgroundColor: const Color(0xFFE6FFFA),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        const Text(
          'Alamat Lengkap',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addressController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Nama jalan, gedung, RT/RW, Kelurahan, Kecamatan, Kabupaten/Kota',
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
