import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lapangku/models/field/field_model.dart';
import 'package:lapangku/services/firebase/field_service.dart';
import 'package:lapangku/controllers/auth/auth_controller.dart';

final fieldServiceProvider = Provider<FieldService>((ref) {
  return FieldService();
});

/// Mengambil dan menyimpan daftar lapangan sementara (cache) agar aplikasi lebih cepat
final fieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  ref.keepAlive();
  final service = ref.watch(fieldServiceProvider);
  return service.getFields();
});

final fieldDetailProvider = FutureProvider.family<FieldModel, String>((ref, id) async {
  final service = ref.watch(fieldServiceProvider);
  return service.getFieldById(id);
});

// Model bantuan untuk menyimpan data lapangan sekaligus info jarak
class FieldWithDistance {
  final FieldModel field;
  final double? distanceInMeters;

  const FieldWithDistance({required this.field, this.distanceInMeters});
}

// Mengurutkan lapangan berdasarkan jarak terdekat dari lokasi pengguna
final sortedFieldsWithDistanceProvider =
    FutureProvider<List<FieldWithDistance>>((ref) async {
  final fields = await ref.watch(fieldsProvider.future);
  final user = ref.watch(authStateProvider).value;

  final userLatLng = user?.alamatLatLng;

  final List<FieldWithDistance> result = fields.map((field) {
    double? distance;
    if (userLatLng != null) {
      distance = Geolocator.distanceBetween(
        userLatLng.latitude,
        userLatLng.longitude,
        field.latitude,
        field.longitude,
      );
    }
    return FieldWithDistance(field: field, distanceInMeters: distance);
  }).toList();

  // Urutkan berdasarkan jarak terdekat jika lokasi user tersedia
  if (userLatLng != null) {
    result.sort((a, b) => a.distanceInMeters!.compareTo(b.distanceInMeters!));
  }

  return result;
});
