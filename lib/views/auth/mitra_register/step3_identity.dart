import 'package:flutter/material.dart';
import 'dart:io';

class Step3Identity extends StatelessWidget {
  final File? ktpPhoto;
  final File? selfiePhoto;
  final VoidCallback onPickKtp;
  final VoidCallback onPickSelfie;

  const Step3Identity({
    super.key,
    required this.ktpPhoto,
    required this.selfiePhoto,
    required this.onPickKtp,
    required this.onPickSelfie,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Verifikasi Identitas',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A202C),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kami butuh ini untuk memastikan kamu pemilik lapangan yang valid',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUploadSection(
                title: 'Foto KTP',
                image: ktpPhoto,
                onTap: onPickKtp,
                icon: Icons.camera_alt_outlined,
                label: 'Upload foto KTP',
                subtitle: 'Format JPG, PNG (Maks 5MB)',
              ),
              const SizedBox(height: 32),
              _buildUploadSection(
                title: 'Selfie dengan KTP',
                image: selfiePhoto,
                onTap: onPickSelfie,
                icon: Icons.face_retouching_natural_outlined,
                label: 'Upload Selfie + KTP',
                subtitle: 'Pegang KTP saat selfie agar data cocok',
              ),
              const SizedBox(height: 32),

              // Blue Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFF2C5282), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Foto harus jelas dan tidak blur. Pastikan seluruh bagian KTP masuk dalam frame kamera.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C5282),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildUploadSection({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: image != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(image, fit: BoxFit.cover),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      const Center(
                        child: Icon(Icons.edit_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0).withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            color: const Color(0xFF4A5568), size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
