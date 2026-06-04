import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class GeolocationService {
  /// Mengonversi teks alamat menjadi koordinat GeoPoint
  /// dengan timeout untuk mencegah loading terlalu lama
  Future<GeoPoint?> getCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) return null;
    
    try {
      // Set timeout 10 detik agar tidak menggantung jika API lambat
      final locations = await locationFromAddress(address).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Geocoding timeout'),
      );
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return GeoPoint(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      // Jika terjadi error (misalnya alamat tidak ditemukan atau timeout),
      // kita return null sehingga alamat teks tetap tersimpan tapi latitude/longitude kosong
      if (kDebugMode) debugPrint('Error geocoding address: $e');
      return null;
    }
  }
}
