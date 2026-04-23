import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lapangku/models/field/field_model.dart';

class CustomerFieldDetailPage extends ConsumerStatefulWidget {
  const CustomerFieldDetailPage({super.key});

  @override
  ConsumerState<CustomerFieldDetailPage> createState() => _CustomerFieldDetailPageState();
}

class _CustomerFieldDetailPageState extends ConsumerState<CustomerFieldDetailPage> {
  final int _selectedTabIndex = 0;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;

  String _formatHarga(int harga) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(harga);
  }

  @override
  Widget build(BuildContext context) {
    final field = ModalRoute.of(context)!.settings.arguments as FieldModel;
    
    // Generate next 7 days for date picker
    final dates = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

    // Dummy time slots
    final timeSlots = [
      {'time': '18:00 - 19:00', 'status': 'available'},
      {'time': '19:00 - 20:00', 'status': 'selected'},
      {'time': '20:00 - 21:00', 'status': 'almost_full'},
      {'time': '21:00 - 22:00', 'status': 'unavailable'},
    ];

    if (_selectedTime == null) {
      _selectedTime = '19:00 - 20:00'; // Default selected for mockup
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Hero Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: field.fotoUtama.isNotEmpty
                ? Image.network(
                    field.fotoUtama,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          
          // Custom App Bar (Floating Icons)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFloatingIcon(Icons.arrow_back, () => Navigator.pop(context)),
                Row(
                  children: [
                    _buildFloatingIcon(Icons.share_rounded, () {}),
                    const SizedBox(width: 12),
                    _buildFloatingIcon(Icons.favorite_border_rounded, () {}),
                  ],
                ),
              ],
            ),
          ),

          // Main Content Panel (overlapping image)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35 - 30,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Draggable handle indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.nama,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                field.alamat,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '1.2 km dari lokasiku',
                                style: TextStyle(color: Color(0xFF0369A1), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              field.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              ' (${field.totalUlasan} ulasan)',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, decoration: TextDecoration.underline),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text('Buka - 06:00-22:00', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Menu
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Info', 'Fasilitas', 'Ulasan', 'Lokasi'].asMap().entries.map((entry) {
                        final isSelected = entry.key == _selectedTabIndex;
                        return Container(
                          padding: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Description
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lapangan Futsal A di GOR Diponegoro menggunakan rumput sintetis standar Internasional yang empuk dan tidak licin. Dilengkapi dengan tribun penonton yang...',
                            style: TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Lihat selengkapnya',
                            style: TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            'PILIH JADWAL',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 12),

                          // Date Picker
                          SizedBox(
                            height: 64,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: dates.length,
                              itemBuilder: (context, index) {
                                final date = dates[index];
                                final isSelected = date.day == _selectedDate.day;
                                final dayName = DateFormat('E', 'id_ID').format(date).toUpperCase();
                                
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedDate = date),
                                  child: Container(
                                    width: 54,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF059669) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayName,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Time Slots Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: timeSlots.length,
                            itemBuilder: (context, index) {
                              final slot = timeSlots[index];
                              final time = slot['time']!;
                              final status = slot['status']!;
                              
                              Color bgColor = Colors.white;
                              Color borderColor = Colors.grey.shade300;
                              Color textColor = const Color(0xFF1E293B);
                              String subText = '';
                              Color subTextColor = Colors.transparent;

                              if (status == 'selected') {
                                bgColor = const Color(0xFF059669);
                                borderColor = const Color(0xFF059669);
                                textColor = Colors.white;
                                subText = 'TERPILIH';
                                subTextColor = Colors.white70;
                              } else if (status == 'available') {
                                borderColor = const Color(0xFF059669);
                                textColor = const Color(0xFF059669);
                              } else if (status == 'almost_full') {
                                bgColor = const Color(0xFFFFF7ED);
                                borderColor = const Color(0xFFFDBA74);
                                textColor = const Color(0xFFC2410C);
                                subText = 'HAMPIR PENUH';
                                subTextColor = const Color(0xFFEA580C);
                              } else if (status == 'unavailable') {
                                bgColor = const Color(0xFFF8FAFC);
                                borderColor = Colors.transparent;
                                textColor = const Color(0xFF94A3B8);
                                subText = 'PENUH';
                                subTextColor = const Color(0xFF94A3B8);
                              }

                              return GestureDetector(
                                onTap: status != 'unavailable' ? () {
                                  setState(() {
                                    _selectedTime = time;
                                  });
                                } : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        time,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (subText.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subText,
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 100), // padding for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categorical Badge (FUTSAL) floating on top of image
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35 - 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6EE7B7), // Light green
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                field.kategori.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      // Sticky Bottom Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('EEEE, d MMM', 'id_ID').format(_selectedDate)} • $_selectedTime',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatHarga(field.hargaPerJam),
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Pesan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFF064E3B), // Dark green placeholder
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 80, color: Colors.white24),
      ),
    );
  }
}
