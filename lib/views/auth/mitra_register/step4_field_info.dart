import 'package:flutter/material.dart';

class Step4FieldInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController ownerNameController;
  final TextEditingController whatsappController;
  final TextEditingController descriptionController;
  final String selectedSport;
  final Function(String) onSportSelected;
  final List<String> selectedFacilities;
  final Function(String) onFacilityToggled;

  static const List<Map<String, dynamic>> _facilitiesList = [
    {'name': 'Parkir', 'icon': Icons.local_parking},
    {'name': 'Toilet', 'icon': Icons.wc},
    {'name': 'Wifi', 'icon': Icons.wifi},
    {'name': 'CCTV', 'icon': Icons.videocam_outlined},
    {'name': 'Mushola', 'icon': Icons.mosque_outlined},
    {'name': 'Kantin', 'icon': Icons.restaurant},
    {'name': 'Ruang Ganti', 'icon': Icons.checkroom},
    {'name': 'Tribun', 'icon': Icons.stadium_outlined},
  ];

  const Step4FieldInfo({
    super.key,
    required this.nameController,
    required this.ownerNameController,
    required this.whatsappController,
    required this.descriptionController,
    required this.selectedSport,
    required this.onSportSelected,
    required this.selectedFacilities,
    required this.onFacilityToggled,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B6B3A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Informasi Lapangan',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A202C),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Isi detail agar mudah ditemukan',
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
              // Nama Pemilik
              _buildLabel('Nama Pemilik'),
              _buildModernTextField(
                controller: ownerNameController,
                hint: 'Contoh: Ahmad Subarjo',
              ),
              const SizedBox(height: 24),

              // Nomor WhatsApp
              _buildLabel('Nomor WhatsApp'),
              _buildModernTextField(
                controller: whatsappController,
                hint: 'Contoh: 081234567890',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Nama Lapangan
              _buildLabel('Nama Lapangan'),
              _buildModernTextField(
                controller: nameController,
                hint: 'Contoh: Arena Futsal Juara',
              ),
              const SizedBox(height: 24),

              // Jenis Olahraga
              _buildLabel('Jenis Olahraga'),
              Wrap(
                spacing: 10,
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
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? primary : const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        sport,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3748),
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Pilih Fasilitas
              const Text(
                'Pilih Fasilitas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B6B3A),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _facilitiesList.length,
                itemBuilder: (context, index) {
                  final facility = _facilitiesList[index];
                  final isSelected =
                      selectedFacilities.contains(facility['name']);
                  return GestureDetector(
                    onTap: () => onFacilityToggled(facility['name'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFFF0F4FF) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primary : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            facility['icon'] as IconData,
                            color:
                                isSelected ? primary : const Color(0xFF4A5568),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            facility['name'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? primary
                                  : const Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Deskripsi Lapangan
              _buildLabel('Deskripsi Lapangan'),
              _buildModernTextField(
                controller: descriptionController,
                hint: 'Ceritakan keunggulan lapangan Anda...',
                maxLines: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A202C),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      ),
    );
  }
}
