import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/mitra/mitra_location_controller.dart';
import 'package:lapangku/views/mitra/mitra_map_picker_page.dart';
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
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push<MapPickerResult>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MitraMapPickerPage(
                        initialLat: locationState.latitude,
                        initialLng: locationState.longitude,
                      ),
                    ),
                  );
                  if (result != null) {
                    ref.read(mitraLocationProvider.notifier).updateLocation(
                          result.latitude,
                          result.longitude,
                        );
                    widget.addressController.text = result.address;
                  }
                },
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: locationState.latitude != null
                          ? const Color(0xFF1B6B3A)
                          : const Color(0xFFE2E8F0),
                      width: locationState.latitude != null ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: const MapPlaceholder(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_outlined,
                                color: Color(0xFF1B6B3A), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              locationState.latitude != null
                                  ? 'Ubah Lokasi di Peta'
                                  : 'Pilih Lokasi di Peta',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (locationState.latitude != null)
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${locationState.latitude!.toStringAsFixed(5)}, ${locationState.longitude!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
