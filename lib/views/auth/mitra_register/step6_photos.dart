import 'package:flutter/material.dart';
import 'dart:io';

class Step6Photos extends StatelessWidget {
  final List<File> fieldPhotos;
  final VoidCallback onPickPhotos;
  final Function(int) onRemovePhoto;

  const Step6Photos({
    super.key,
    required this.fieldPhotos,
    required this.onPickPhotos,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Foto Lapangan',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A202C),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tampilkan kondisi terbaik lapangan kamu',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Galeri Foto',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF8F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Minimal 2 foto',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B6B3A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: 4, // Show 4 slots total
                itemBuilder: (context, index) {
                  if (index < fieldPhotos.length) {
                    return _buildImageItem(index);
                  } else if (index == fieldPhotos.length) {
                    return _buildUploadSlot(onPickPhotos, isMain: index == 0);
                  } else {
                    return _buildPlaceholderSlot();
                  }
                },
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Format: JPG, PNG. Maks 5MB per foto.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA0AEC0),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildImageItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: FileImage(fieldPhotos[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => onRemovePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSlot(VoidCallback onTap, {bool isMain = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF2F7).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMain ? Icons.add_a_photo_outlined : Icons.add,
                color: const Color(0xFF4A5568),
                size: 24,
              ),
            ),
            if (isMain) ...[
              const SizedBox(height: 8),
              const Text(
                'Tambah Foto',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderSlot() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          color: Color(0xFFE2E8F0),
          size: 24,
        ),
      ),
    );
  }
}
