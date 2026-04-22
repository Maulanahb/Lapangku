import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/models/owner/owner_field_model.dart';
import 'package:lapangku/services/firebase/owner_service.dart';

// Provider untuk OwnerService
final ownerServiceProvider = Provider<OwnerService>((ref) {
  return OwnerService();
});

// FutureProvider untuk mengambil data lapangan dari Firestore
// Kita pakai .family karena kita butuh passing ownerId (UID user yang login)
final ownerFieldsProvider = FutureProvider.family<List<OwnerFieldModel>, String>((ref, ownerId) async {
  final service = ref.watch(ownerServiceProvider);
  return service.getOwnerFields(ownerId);
});
