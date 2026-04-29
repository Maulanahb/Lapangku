import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_location_controller.dart';
import 'widgets/map_placeholder.dart';

class Step5Location extends ConsumerStatefulWidget {
  final TextEditingController addressController;

  const Step5Location({
    super.key,
    required this.addressController,
  });

  @override
  ConsumerState<Step5Location> createState() => _Step5LocationState();
}

class _Step5LocationState extends ConsumerState<Step5Location> {
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B6B3A);
    final locationState = ref.watch(mitraLocationProvider);

    // Update text controller when location is found
    ref.listen<LocationState>(mitraLocationProvider, (previous, next) {
      if (previous?.address != next.address && next.address.isNotEmpty) {
        widget.addressController.text = next.address;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Temukan Lokasi',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A202C),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pastikan lokasi akurat agar mudah ditemukan',
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
              // Map Area
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const MapPlaceholder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Use My Location Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton.icon(
                  onPressed: locationState.isLoading
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(mitraLocationProvider.notifier)
                                .getCurrentLocation();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(e
                                          .toString()
                                          .replaceAll('Exception: ', ''))));
                            }
                          }
                        },
                  icon: locationState.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF2C5282)))
                      : const Icon(Icons.my_location_rounded,
                          size: 20, color: Color(0xFF2C5282)),
                  label: Text(
                    locationState.isLoading
                        ? 'Mencari...'
                        : 'Gunakan lokasi saya',
                    style: const TextStyle(
                      color: Color(0xFF2C5282),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEDF2FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Alamat Lengkap
              const Text(
                'Alamat Lengkap',
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
                  controller: widget.addressController,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                        'Nama jalan, gedung, RT/RW, Kelurahan, Kecamatan, Kabupaten/Kota',
                    hintStyle: TextStyle(
                      color: Color(0xFFA0AEC0),
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
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
}
