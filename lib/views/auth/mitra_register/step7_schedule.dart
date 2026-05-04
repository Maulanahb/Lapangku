import 'package:flutter/material.dart';

class Step7Schedule extends StatelessWidget {
  final TextEditingController priceController;
  final TimeOfDay openingTime;
  final TimeOfDay closingTime;
  final List<String> selectedDays;
  final List<String> selectedFacilities;
  final VoidCallback onPickOpeningTime;
  final VoidCallback onPickClosingTime;
  final Function(String) onDayToggled;
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

  const Step7Schedule({
    super.key,
    required this.priceController,
    required this.openingTime,
    required this.closingTime,
    required this.selectedDays,
    required this.selectedFacilities,
    required this.onPickOpeningTime,
    required this.onPickClosingTime,
    required this.onDayToggled,
    required this.onFacilityToggled,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B6B3A);
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Harga & Jadwal',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A202C),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Masukan harga per jam dan hari operasional',
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
              // Harga per jam
              const Text(
                'Harga per jam',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text('Rp',
                          style: TextStyle(
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                    hintText: '0',
                    hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Jam Buka & Tutup
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam buka',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A202C))),
                        const SizedBox(height: 10),
                        _buildTimePicker(
                            context, openingTime, onPickOpeningTime),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam tutup',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A202C))),
                        const SizedBox(height: 10),
                        _buildTimePicker(
                            context, closingTime, onPickClosingTime),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Hari Operasional
              const Text(
                'Hari Operasional',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: days.map((day) {
                  final isSelected = selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () => onDayToggled(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primary : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4A5568),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTimePicker(
      BuildContext context, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const Icon(Icons.access_time_rounded,
                color: Color(0xFF718096), size: 20),
          ],
        ),
      ),
    );
  }
}
