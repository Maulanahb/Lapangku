import 'package:flutter/material.dart';
import 'widgets/upload_card.dart';

class Step2Identity extends StatelessWidget {
  const Step2Identity({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Verifikasi Identitas',
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
            'Kami butuh ini untuk memastikan kamu pemilik lapangan yang valid',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Foto KTP Section
        const UploadCard(
          title: 'Foto KTP',
          icon: Icons.camera_alt_outlined,
          label: 'Upload foto KTP',
          subtitle: 'Format JPG, PNG (Maks 5MB)',
        ),

        const SizedBox(height: 24),

        // Selfie Section
        const UploadCard(
          title: 'Selfie dengan KTP',
          icon: Icons.face_outlined,
          label: 'Upload Selfie + KTP',
          subtitle: 'Pegang KTP saat selfie agar data cocok',
        ),

        const SizedBox(height: 24),

        // Info Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  color: Color(0xFF3182CE), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Foto harus jelas dan tidak blur. Pastikan seluruh bagian KTP masuk dalam frame kamera.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C5282),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
