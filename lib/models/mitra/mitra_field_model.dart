import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/models/field/base_field_model.dart';

class MitraFieldModel extends BaseFieldModel {
  final String id; // alias dari fieldId untuk backward-compat
  final String jenisLapangan; // futsal, badminton, basket, tenis, voli
  final String deskripsi;
  final String alamat;
  final double latitude;
  final double longitude;
  final List<String> photoUrls;
  final List<String> fasilitas;
  final int? hargaWeekend;
  final String jamBuka;
  final String jamTutup;
  final bool isActive;
  final DateTime? createdAt;

  const MitraFieldModel({
    required this.id,
    required String mitraId,
    String namaVenue = '',
    required String namaLapangan,
    required this.jenisLapangan,
    required int hargaPerJam,
    this.deskripsi = '',
    this.alamat = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.photoUrls = const [],
    this.fasilitas = const [],
    this.hargaWeekend,
    this.jamBuka = '08:00',
    this.jamTutup = '22:00',
    this.isActive = true,
    this.createdAt,
  }) : super(
          fieldId: id,
          mitraId: mitraId,
          namaVenue: namaVenue,
          namaLapangan: namaLapangan,
          hargaPerJam: hargaPerJam,
        );

  // Backward-compat getters
  String get name => namaLapangan;
  int get pricePerHour => hargaPerJam;

  /// Backward-compat getter: tetap bisa akses .MitraId (kapital M)
  String get MitraId => mitraId;

  MitraFieldModel copyWith({
    String? id,
    String? mitraId,
    String? namaVenue,
    String? namaLapangan,
    String? jenisLapangan,
    int? hargaPerJam,
    String? deskripsi,
    String? alamat,
    double? latitude,
    double? longitude,
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
      mitraId: mitraId ?? this.mitraId,
      namaVenue: namaVenue ?? this.namaVenue,
      namaLapangan: namaLapangan ?? this.namaLapangan,
      jenisLapangan: jenisLapangan ?? this.jenisLapangan,
      hargaPerJam: hargaPerJam ?? this.hargaPerJam,
      deskripsi: deskripsi ?? this.deskripsi,
      alamat: alamat ?? this.alamat,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
      'mitraId': mitraId,
      'MitraId': mitraId, // backward-compat key (kapital M)
      'id_pemilik': mitraId, // backward-compat key untuk Customer FieldModel
      'nama_venue': namaVenue,
      'nama_lapangan': namaLapangan,
      'jenisLapangan': jenisLapangan,
      'kategori_lapangan': jenisLapangan, // backward-compat key untuk Customer
      'hargaPerJam': hargaPerJam,
      'harga_sewa_jam': hargaPerJam, // backward-compat key untuk Customer
      'deskripsi': deskripsi,
      'deskripsi_fasilitas': deskripsi, // backward-compat key untuk Customer
      'alamat': alamat,
      'alamat_lengkap': alamat, // backward-compat key untuk Customer
      'location': (latitude != 0.0 && longitude != 0.0)
          ? GeoPoint(latitude, longitude)
          : null, // GeoPoint untuk Customer Maps
      'photoUrls': photoUrls,
      'foto_lapangan': photoUrls, // backward-compat key untuk Customer
      'fasilitas': fasilitas,
      'hargaWeekend': hargaWeekend,
      'jamBuka': jamBuka,
      'jamTutup': jamTutup,
      'is_aktif': isActive, // ✅ Sesuai key yang dibaca Customer
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory MitraFieldModel.fromMap(Map<String, dynamic> map, String id) {
    return MitraFieldModel(
      id: id,
      mitraId: map['mitraId'] ?? map['MitraId'] ?? map['id_pemilik'] ?? map['uid'] ?? '',
      namaVenue: map['nama_venue'] ?? map['namaVenue'] ?? '',
      namaLapangan: map['nama_lapangan'] ?? map['namaLapangan'] ??
          map['businessName'] ??
          map['namaBisnis'] ??
          map['name'] ??
          '',
      jenisLapangan: map['jenisLapangan'] ?? 'Futsal',
      hargaPerJam: (map['hargaPerJam'] ?? map['pricePerHour'] ?? 0) as int,
      deskripsi: map['deskripsi'] ?? '',
      alamat: map['alamat'] ?? map['alamat_lengkap'] ?? '',
      latitude: _extractLat(map),
      longitude: _extractLng(map),
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
      isActive: map['is_aktif'] ?? map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static double _extractLat(Map<String, dynamic> map) {
    if (map['location'] is GeoPoint) return (map['location'] as GeoPoint).latitude;
    return (map['latitude'] ?? 0.0).toDouble();
  }

  static double _extractLng(Map<String, dynamic> map) {
    if (map['location'] is GeoPoint) return (map['location'] as GeoPoint).longitude;
    return (map['longitude'] ?? 0.0).toDouble();
  }
}
