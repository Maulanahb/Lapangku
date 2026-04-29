// Deprecated: Gunakan lib/features/owner/field/providers/owner_field_provider.dart
// File ini dipertahankan untuk menghindari breaking changes pada import lama.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapangku/features/owner/field/models/owner_field_model.dart';
import 'package:lapangku/features/owner/field/providers/owner_field_provider.dart';
import 'package:lapangku/services/firebase/owner_service.dart';

export 'package:lapangku/features/owner/field/providers/owner_field_provider.dart';

// Re-export untuk backward-compat
final ownerFieldsProvider =
    FutureProvider.family<List<OwnerFieldModel>, String>((ref, ownerId) async {
  final service = OwnerService();
  return service.getOwnerFields(ownerId);
});
