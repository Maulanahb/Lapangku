import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/controllers/Mitra/Mitra_location_controller.dart';
import 'widgets/map_placeholder.dart';

class Step4Location extends ConsumerStatefulWidget {
  final TextEditingController addressController;

  const Step4Location({
    super.key,
    required this.addressController,
  });

  @override
  ConsumerState<Step4Location> createState() => _Step4LocationState();
}

class _Step4LocationState extends ConsumerState<Step4Location> {
  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(MitraLocationProvider);

    // Gunakan ref.listen agar text controller hanya diupdate SAAT state berubah (selesai loading lokasi)
    // bukan setiap kali widget direbuild.
    ref.listen<LocationState>(MitraLocationProvider, (previous, next) {
      if (previous?.address != next.address && next.address.isNotEmpty) {
        widget.addressController.text = next.address;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Temukan Lokasi',
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
            'Pastikan lokasi akurat agar mudah ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Mengembalikan Map Placeholder (Gambar statis)
        const MapPlaceholder(),

        const SizedBox(height: 16),

        // Gunakan lokasi saya button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: locationState.isLoading ? null : () async {
               try {
                 await ref.read(MitraLocationProvider.notifier).getCurrentLocation();
               } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                 }
               }
            },
            icon: locationState.isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B6B3A))
                  )
                : const Icon(Icons.my_location, size: 20),
            label: Text(locationState.isLoading ? 'Mencari lokasi...' : 'Gunakan lokasi saya'),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFF1B6B3A),
              backgroundColor: const Color(0xFFE6FFFA),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        const Text(
          'Alamat Lengkap',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.addressController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Nama jalan, gedung, RT/RW, Kelurahan, Kecamatan, Kabupaten/Kota',
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
