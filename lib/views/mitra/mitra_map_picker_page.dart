import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  const MapPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class MitraMapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MitraMapPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<MitraMapPickerPage> createState() => _MitraMapPickerPageState();
}

class _MitraMapPickerPageState extends State<MitraMapPickerPage> {
  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(-7.9666, 112.6326); // Default: Malang
  String _currentAddress = 'Geser pin untuk memilih lokasi...';
  bool _isLoadingAddress = false;
  bool _isLocating = false;

  static const Color _primaryGreen = Color(0xFF0F5A3C);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null &&
        widget.initialLng != null &&
        widget.initialLat != 0.0 &&
        widget.initialLng != 0.0) {
      _selectedPosition = LatLng(widget.initialLat!, widget.initialLng!);
      _reverseGeocode(_selectedPosition);
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks[0];
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.subAdministrativeArea != null &&
              p.subAdministrativeArea!.isNotEmpty)
            p.subAdministrativeArea!,
          if (p.administrativeArea != null &&
              p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
          if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
        ];
        setState(() => _currentAddress = parts.join(', '));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _currentAddress = 'Gagal mendapatkan alamat');
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS tidak aktif. Aktifkan di pengaturan.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak permanen. Ubah di pengaturan.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final newPos = LatLng(position.latitude, position.longitude);

      setState(() => _selectedPosition = newPos);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 17));
      await _reverseGeocode(newPos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _confirmLocation() {
    Navigator.pop(
      context,
      MapPickerResult(
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        address: _currentAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              setState(() => _selectedPosition = position.target);
            },
            onCameraIdle: () {
              _reverseGeocode(_selectedPosition);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ── Center Pin ──
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(Icons.location_on, size: 48, color: _primaryGreen),
            ),
          ),

          // ── Top Bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: _primaryGreen),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Pilih Lokasi Lapangan',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── My Location FAB ──
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              onPressed: _isLocating ? null : _goToMyLocation,
              backgroundColor: Colors.white,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryGreen,
                      ),
                    )
                  : const Icon(Icons.my_location, color: _primaryGreen),
            ),
          ),

          // ── Bottom Card ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on,
                            color: _primaryGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lokasi Terpilih',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            _isLoadingAddress
                                ? Row(children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primaryGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Mencari alamat...',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13)),
                                  ])
                                : Text(
                                    _currentAddress,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A202C),
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingAddress ? null : _confirmLocation,
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('Pilih Lokasi Ini',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
