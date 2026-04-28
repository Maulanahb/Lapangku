import 'dart:io';
import 'package:flutter/material.dart';
import 'widgets/upload_card.dart';

class Step2Identity extends StatelessWidget {
  final File? ktpPhoto;
  final File? selfiePhoto;
  final VoidCallback onPickKtp;
  final VoidCallback onPickSelfie;

  const Step2Identity({
    super.key,
    this.ktpPhoto,
    this.selfiePhoto,
    required this.onPickKtp,
    required this.onPickSelfie,
  });

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
        UploadCard(
          title: 'Foto KTP',
          icon: Icons.camera_alt_outlined,
          label: ktpPhoto != null ? 'KTP Terpilih' : 'Upload foto KTP',
          subtitle: ktpPhoto != null ? 'Klik untuk mengubah' : 'Format JPG, PNG (Maks 5MB)',
          imageFile: ktpPhoto,
          onTap: onPickKtp,
        ),

        const SizedBox(height: 24),

        // Selfie Section
        UploadCard(
          title: 'Selfie dengan KTP',
          icon: Icons.face_outlined,
          label: selfiePhoto != null ? 'Selfie Terpilih' : 'Upload Selfie + KTP',
          subtitle: selfiePhoto != null ? 'Klik untuk mengubah' : 'Pegang KTP saat selfie agar data cocok',
          imageFile: selfiePhoto,
          onTap: onPickSelfie,
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
