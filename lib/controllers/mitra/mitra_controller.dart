import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/Mitra/Mitra_field_model.dart';
import 'package:lapangku/services/firebase/Mitra_service.dart';

// Provider untuk MitraService
final MitraServiceProvider = Provider<MitraService>((ref) {
  return MitraService();
});

// FutureProvider untuk mengambil data lapangan dari Firestore
// Kita pakai .family karena kita butuh passing MitraId (UID user yang login)
final MitraFieldsProvider = FutureProvider.family<List<MitraFieldModel>, String>((ref, MitraId) async {
  final service = ref.watch(MitraServiceProvider);
  return service.getMitraFields(MitraId);
});
