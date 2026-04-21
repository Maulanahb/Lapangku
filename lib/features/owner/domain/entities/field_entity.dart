// lib/features/owner/domain/entities/field_entity.dart

class FieldEntity {
  final String id;
  final String ownerId; // Penting untuk filter: where('ownerId', isEqualTo: currentUser.uid)
  final String name;
  final String location;
  final int pricePerHour;
  final String statusVerifikasi; // Buat nyambung sama fiturnya Galuh (Admin)

  FieldEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.location,
    required this.pricePerHour,
    required this.statusVerifikasi,
  });
}