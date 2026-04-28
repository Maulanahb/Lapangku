import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationState {
  final double? latitude;
  final double? longitude;
  final String address;
  final bool isLoading;

  LocationState({
    this.latitude,
    this.longitude,
    this.address = '',
    this.isLoading = false,
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    String? address,
    bool? isLoading,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OwnerLocationNotifier extends StateNotifier<LocationState> {
  OwnerLocationNotifier() : super(LocationState());

  // Dipanggil saat tombol "Gunakan lokasi saya" ditekan
  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(isLoading: false);
      throw Exception(
          'Layanan Lokasi (GPS) tidak aktif. Silakan aktifkan di pengaturan HP Anda.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(isLoading: false);
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(isLoading: false);
      throw Exception(
          'Izin lokasi ditolak permanen. Silakan ubah di pengaturan aplikasi.');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await updateLocation(position.latitude, position.longitude);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception('Gagal mendapatkan lokasi: $e');
    }
  }

  // Dipanggil saat pin map digeser secara manual
  Future<void> updateLocation(double lat, double lng) async {
    state = state.copyWith(isLoading: true, latitude: lat, longitude: lng);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty)
          addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty)
          addressParts.add(place.locality!);
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty)
          addressParts.add(place.subAdministrativeArea!);
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          addressParts.add(place.administrativeArea!);
        if (place.postalCode != null && place.postalCode!.isNotEmpty)
          addressParts.add(place.postalCode!);

        String address = addressParts.join(', ');
        state = state.copyWith(address: address, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Provider yang akan digunakan di UI
final ownerLocationProvider =
    StateNotifierProvider<OwnerLocationNotifier, LocationState>((ref) {
  return OwnerLocationNotifier();
});
