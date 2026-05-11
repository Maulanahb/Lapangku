import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/mitra/mitra_field_model.dart';
import 'package:lapangku/services/firebase/mitra_service.dart';

// Provider untuk MitraService
final mitraServiceProvider = Provider<MitraService>((ref) {
  return MitraService();
});

// FutureProvider untuk mengambil data lapangan dari Firestore
// Kita pakai .family karena kita butuh passing MitraId (UID user yang login)
final mitraFieldsProvider = FutureProvider.family<List<MitraFieldModel>, String>((ref, mitraId) async {
  final service = ref.watch(mitraServiceProvider);
  return service.getMitraFields(mitraId);
});
