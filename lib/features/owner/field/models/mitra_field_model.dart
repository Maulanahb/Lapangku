import 'package:cloud_firestore/cloud_firestore.dart';

class MitraFieldModel {
  final String id;
  final String MitraId;
  final String namaLapangan;
  final String jenisLapangan; // futsal, badminton, basket, tenis, voli
  final int hargaPerJam;
  final String deskripsi;
  final String alamat;
  final List<String> photoUrls;
  final List<String> fasilitas;
  final bool isActive;
  final DateTime? createdAt;

  const MitraFieldModel({
    required this.id,
    required this.MitraId,
    required this.namaLapangan,
    required this.jenisLapangan,
    required this.hargaPerJam,
    this.deskripsi = '',
    this.alamat = '',
    this.photoUrls = const [],
    this.fasilitas = const [],
    this.isActive = true,
    this.createdAt,
  });

  // Backward-compat getters
  String get name => namaLapangan;
  int get pricePerHour => hargaPerJam;

  MitraFieldModel copyWith({
    String? id,
    String? MitraId,
    String? namaLapangan,
    String? jenisLapangan,
    int? hargaPerJam,
    String? deskripsi,
    String? alamat,
    List<String>? photoUrls,
    List<String>? fasilitas,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MitraFieldModel(
      id: id ?? this.id,
      MitraId: MitraId ?? this.MitraId,
      namaLapangan: namaLapangan ?? this.namaLapangan,
      jenisLapangan: jenisLapangan ?? this.jenisLapangan,
      hargaPerJam: hargaPerJam ?? this.hargaPerJam,
      deskripsi: deskripsi ?? this.deskripsi,
      alamat: alamat ?? this.alamat,
      photoUrls: photoUrls ?? this.photoUrls,
      fasilitas: fasilitas ?? this.fasilitas,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'MitraId': MitraId,
      'namaLapangan': namaLapangan,
      'jenisLapangan': jenisLapangan,
      'hargaPerJam': hargaPerJam,
      'deskripsi': deskripsi,
      'alamat': alamat,
      'photoUrls': photoUrls,
      'fasilitas': fasilitas,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory MitraFieldModel.fromMap(Map<String, dynamic> map, String id) {
    return MitraFieldModel(
      id: id,
      MitraId: map['MitraId'] ?? '',
      namaLapangan: map['namaLapangan'] ?? map['name'] ?? '',
      jenisLapangan: map['jenisLapangan'] ?? 'Futsal',
      hargaPerJam: (map['hargaPerJam'] ?? map['pricePerHour'] ?? 0) as int,
      deskripsi: map['deskripsi'] ?? '',
      alamat: map['alamat'] ?? map['location'] ?? '',
      photoUrls: map['photoUrls'] != null
          ? List<String>.from(map['photoUrls'])
          : [],
      fasilitas: map['fasilitas'] != null
          ? List<String>.from(map['fasilitas'])
          : [],
      isActive: map['isActive'] ?? map['statusVerifikasi'] == 'aktif' ? true : (map['isActive'] ?? true),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
