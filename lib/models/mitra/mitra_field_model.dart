import 'package:cloud_firestore/cloud_firestore.dart';

class MitraFieldModel {
  final String id;
  final String MitraId;
  final String namaVenue;
  final String namaLapangan;
  final String jenisLapangan; // futsal, badminton, basket, tenis, voli
  final int hargaPerJam;
  final String deskripsi;
  final String alamat;
  final List<String> photoUrls;
  final List<String> fasilitas;
  final int? hargaWeekend;
  final String jamBuka;
  final String jamTutup;
  final bool isActive;
  final DateTime? createdAt;

  const MitraFieldModel({
    required this.id,
    required this.MitraId,
    this.namaVenue = '',
    required this.namaLapangan,
    required this.jenisLapangan,
    required this.hargaPerJam,
    this.deskripsi = '',
    this.alamat = '',
    this.photoUrls = const [],
    this.fasilitas = const [],
    this.hargaWeekend,
    this.jamBuka = '08:00',
    this.jamTutup = '22:00',
    this.isActive = true,
    this.createdAt,
  });

  // Backward-compat getters
  String get name => namaLapangan;
  int get pricePerHour => hargaPerJam;

  MitraFieldModel copyWith({
    String? id,
    String? MitraId,
    String? namaVenue,
    String? namaLapangan,
    String? jenisLapangan,
    int? hargaPerJam,
    String? deskripsi,
    String? alamat,
    List<String>? photoUrls,
    List<String>? fasilitas,
    int? hargaWeekend,
    String? jamBuka,
    String? jamTutup,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MitraFieldModel(
      id: id ?? this.id,
      MitraId: MitraId ?? this.MitraId,
      namaVenue: namaVenue ?? this.namaVenue,
      namaLapangan: namaLapangan ?? this.namaLapangan,
      jenisLapangan: jenisLapangan ?? this.jenisLapangan,
      hargaPerJam: hargaPerJam ?? this.hargaPerJam,
      deskripsi: deskripsi ?? this.deskripsi,
      alamat: alamat ?? this.alamat,
      photoUrls: photoUrls ?? this.photoUrls,
      fasilitas: fasilitas ?? this.fasilitas,
      hargaWeekend: hargaWeekend ?? this.hargaWeekend,
      jamBuka: jamBuka ?? this.jamBuka,
      jamTutup: jamTutup ?? this.jamTutup,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'MitraId': MitraId,
      'nama_venue': namaVenue,
      'nama_lapangan': namaLapangan,
      'jenisLapangan': jenisLapangan,
      'hargaPerJam': hargaPerJam,
      'deskripsi': deskripsi,
      'alamat': alamat,
      'photoUrls': photoUrls,
      'fasilitas': fasilitas,
      'hargaWeekend': hargaWeekend,
      'jamBuka': jamBuka,
      'jamTutup': jamTutup,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory MitraFieldModel.fromMap(Map<String, dynamic> map, String id) {
    return MitraFieldModel(
      id: id,
      MitraId: map['MitraId'] ?? map['uid'] ?? '',
      namaVenue: map['nama_venue'] ?? map['namaVenue'] ?? '',
      namaLapangan: map['nama_lapangan'] ?? map['namaLapangan'] ??
          map['businessName'] ??
          map['namaBisnis'] ??
          map['name'] ??
          '',
      jenisLapangan: map['jenisLapangan'] ?? 'Futsal',
      hargaPerJam: (map['hargaPerJam'] ?? map['pricePerHour'] ?? 0) as int,
      deskripsi: map['deskripsi'] ?? '',
      alamat: map['alamat'] ?? map['location'] ?? '',
      photoUrls: (map['photoUrls'] as List?)?.map((e) => e.toString()).toList() ??
          (map['photos'] as List?)?.map((e) => e.toString()).toList() ??
          (map['images'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      fasilitas: (map['fasilitas'] as List?)?.map((e) => e.toString()).toList() ??
          (map['facilities'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      hargaWeekend: map['hargaWeekend'] as int?,
      jamBuka: map['jamBuka'] ?? '08:00',
      jamTutup: map['jamTutup'] ?? '22:00',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
