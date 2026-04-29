import 'package:flutter/material.dart';

class Step3FieldInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String selectedSport;
  final Function(String) onSportSelected;
  final List<String> selectedFacilities;
  final Function(String) onFacilityToggled;

  static const List<Map<String, dynamic>> _facilities = [
    {'name': 'Parkir', 'icon': Icons.local_parking},
    {'name': 'Toilet', 'icon': Icons.wc},
    {'name': 'Wifi', 'icon': Icons.wifi},
    {'name': 'CCTV', 'icon': Icons.videocam_outlined},
    {'name': 'Mushola', 'icon': Icons.mosque_outlined},
    {'name': 'Kantin', 'icon': Icons.restaurant},
    {'name': 'Ruang Ganti', 'icon': Icons.checkroom},
    {'name': 'Tribun', 'icon': Icons.stadium_outlined},
  ];

  const Step3FieldInfo({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.selectedSport,
    required this.onSportSelected,
    required this.selectedFacilities,
    required this.onFacilityToggled,
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

              // Fasilitas
              const Text(
                'Pilih Fasilitas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F5A2F),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _facilities.length,
                itemBuilder: (context, index) {
                  final facility = _facilities[index];
                  final isSelected =
                      selectedFacilities.contains(facility['name']);
                  return GestureDetector(
                    onTap: () => onFacilityToggled(facility['name'] as String),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEBF8F2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1B6B3A)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            facility['icon'] as IconData,
                            color: isSelected
                                ? const Color(0xFF1B6B3A)
                                : const Color(0xFF4A5568),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            facility['name'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF1B6B3A)
                                  : const Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
