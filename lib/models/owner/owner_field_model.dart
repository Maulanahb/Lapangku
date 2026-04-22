// lib/models/owner/owner_field_model.dart

class OwnerFieldModel {
  final String id;
  final String ownerId; // Penting untuk filter: where('ownerId', isEqualTo: currentUser.uid)
  final String name;
  final String location;
  final int pricePerHour;
  final String statusVerifikasi; // Buat nyambung sama fiturnya Admin

  OwnerFieldModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.location,
    required this.pricePerHour,
    required this.statusVerifikasi,
  });
}
