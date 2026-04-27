import 'package:flutter/material.dart';

class Step3FieldInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String selectedSport;
  final Function(String) onSportSelected;

  const Step3FieldInfo({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.selectedSport,
    required this.onSportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Informasi Lapangan',
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
            'Isi detail agar mudah ditemukan',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Lapangan
              const Text(
                'Nama Lapangan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Arena Futsal Juara',
                  hintStyle:
                      const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 24),

              // Jenis Olahraga
              const Text(
                'Jenis Olahraga',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  'Futsal',
                  'Badminton',
                  'Basket',
                  'Mini Soccer',
                  'Voli'
                ].map((sport) {
                  bool isSelected = selectedSport == sport;
                  return GestureDetector(
                    onTap: () => onSportSelected(sport),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1B6B3A)
                            : const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sport,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3748),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Deskripsi Lapangan
              const Text(
                'Deskripsi Lapangan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ceritakan keunggulan lapangan Anda...',
                  hintStyle:
                      const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
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
