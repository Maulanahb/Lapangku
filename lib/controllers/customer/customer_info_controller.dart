import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/auth/user_model.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';
import 'package:lapangku/services/geolocation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/core/services/firestore_service.dart';

// Hasil penyimpanan profil (untuk mengecek apakah geocoding alamat gagal atau tidak)
class ProfileUpdateResult {
  final bool geocodingFailed;

  const ProfileUpdateResult({this.geocodingFailed = false});
}

class CustomerInfoController {
  final Ref _ref;
  final GeolocationService _geolocationService = GeolocationService();

  CustomerInfoController(this._ref);

  // Menghitung persentase kelengkapan profil (berdasarkan 6 field utama)
  double calculateProgress(UserModel user) {
    int totalFields = 6;
    int filledFields = 0;

    if (user.nama.trim().isNotEmpty && user.nama != 'User Tanpa Nama') filledFields++;
    if (user.phone != null && user.phone!.trim().isNotEmpty) filledFields++;
    if (user.birthday != null && user.birthday!.trim().isNotEmpty) filledFields++;
    if (user.gender != null && user.gender!.trim().isNotEmpty) filledFields++;
    if (user.city != null && user.city!.trim().isNotEmpty) filledFields++;
    if (user.address != null && user.address!.trim().isNotEmpty) filledFields++;

    return filledFields / totalFields;
  }

  // Menyimpan data profil Customer ke database (termasuk memproses koordinat alamat jika berubah)
  Future<ProfileUpdateResult> updateCustomerProfile({
    required String nama,
    required String phone,
    String? birthday,
    String? gender,
    String? city,
    String? address,
  }) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) throw Exception('User tidak login');

    // Validasi
    if (nama.trim().length < 3) {
      throw Exception('Nama lengkap minimal 3 karakter');
    }
    if (phone.trim().length < 10) {
      throw Exception('Nomor HP minimal 10 digit');
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone.trim())) {
      throw Exception('Nomor HP hanya boleh berisi angka');
    }

    GeoPoint? alamatLatLng;
    bool geocodingFailed = false;

    if (address != null && address.trim().isNotEmpty) {
      if (user.address != address || user.alamatLatLng == null) {
        // Alamat berubah atau belum pernah di-geocode → coba geocoding
        try {
          alamatLatLng = await _geolocationService.getCoordinatesFromAddress(address);
          if (alamatLatLng == null) {
            // Geocoding berhasil tapi tidak menemukan lokasi → fallback ke koordinat lama
            geocodingFailed = true;
            alamatLatLng = user.alamatLatLng;
          }
        } catch (e) {
          // Geocoding error (timeout, API down, sinyal buruk) →
          // fallback: tetap simpan profil, pertahankan koordinat lama
          geocodingFailed = true;
          alamatLatLng = user.alamatLatLng;
        }
      } else {
        // Alamat tidak berubah → gunakan koordinat yang sudah ada
        alamatLatLng = user.alamatLatLng;
      }
    }

    // Standarisasi penyimpanan field: gunakan 'nama' bukan 'name'
    final updatedData = {
      'nama': nama.trim(),
      'phone': phone.trim(),
      'birthday': birthday,
      'gender': gender,
      'city': city,
      'address': address,
      if (alamatLatLng != null) 'alamatLatLng': alamatLatLng,
    };

    // Update to Firestore using the correct database instance
    await FirestoreService.instance.collection('users').doc(user.uid).update(updatedData);

    // Refresh auth state to get the latest user data
    _ref.invalidate(authStateProvider);

    return ProfileUpdateResult(geocodingFailed: geocodingFailed);
  }
}

final customerInfoControllerProvider = Provider<CustomerInfoController>((ref) {
  return CustomerInfoController(ref);
});

