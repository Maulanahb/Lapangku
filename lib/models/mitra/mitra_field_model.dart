// lib/models/Mitra/Mitra_field_model.dart

class MitraFieldModel {
  final String id;
  final String MitraId; // Penting untuk filter: where('MitraId', isEqualTo: currentUser.uid)
  final String name;
  final String location;
  final int pricePerHour;
  final String statusVerifikasi; // Buat nyambung sama fiturnya Admin

  MitraFieldModel({
    required this.id,
    required this.MitraId,
    required this.name,
    required this.location,
    required this.pricePerHour,
    required this.statusVerifikasi,
  });
}
