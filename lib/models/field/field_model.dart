import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapangku/models/field/base_field_model.dart';

class FieldModel extends BaseFieldModel {
  final String id; // alias dari fieldId untuk backward-compat
  final String kategori;
  final String alamat;
  final double latitude;
  final double longitude;
  final String deskripsi;
  final bool isAktif;
  final double ratingAvg;
  final int totalUlasan;
  final String fotoUtama;
  final List<String> fotoGaleri;
  final List<String> fasilitas;
  final String? statusVerifikasi;

  const FieldModel({
    required this.id,
    String fieldId = '',
    String mitraId = '',
    String namaVenue = '',
    required String nama,
    required this.kategori,
    required int hargaPerJam,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.deskripsi,
    required this.isAktif,
    required this.ratingAvg,
    required this.totalUlasan,
    required this.fotoUtama,
    required this.fotoGaleri,
    required this.fasilitas,
    this.statusVerifikasi,
  }) : super(
          fieldId: fieldId == '' ? id : fieldId,
          mitraId: mitraId,
          namaVenue: namaVenue,
          namaLapangan: nama,
          hargaPerJam: hargaPerJam,
        );

  /// Backward-compat getter: tetap bisa akses .nama
  String get nama => namaLapangan;

  /// Backward-compat getter: tetap bisa akses .idPemilik
  String get idPemilik => mitraId;

  /// Backward-compat getter: tetap bisa akses .idLapangan
  String get idLapangan => fieldId;

  factory FieldModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final fotoLapangan = List<String>.from(data['foto_lapangan'] ?? []);

    double lat = 0.0;
    double lng = 0.0;
    if (data['location'] != null) {
      try {
        lat = (data['location'] as GeoPoint).latitude;
        lng = (data['location'] as GeoPoint).longitude;
      } catch (_) {}
    }

    return FieldModel(
      id: doc.id,
      fieldId: data['id_lapangan'] ?? data['fieldId'] ?? '',
      mitraId: data['mitraId'] ?? data['id_pemilik'] ?? data['MitraId'] ?? '',
      namaVenue: data['nama_venue'] ?? data['namaVenue'] ?? '',
      nama: data['nama_lapangan'] ?? '',
      kategori: data['kategori_lapangan'] ?? '',
      hargaPerJam: (data['harga_sewa_jam'] ?? 0).toInt(),
      alamat: data['alamat_lengkap'] ?? data['alamat'] ?? '',
      latitude: lat,
      longitude: lng,
      deskripsi: data['deskripsi_fasilitas'] ?? '',
      isAktif: data['is_aktif'] ?? true,
      ratingAvg: (data['avg_rating'] ?? 0).toDouble(),
      totalUlasan: (data['total_ulasan'] ?? 0).toInt(),
      fotoUtama: fotoLapangan.isNotEmpty ? fotoLapangan.first : '',
      fotoGaleri: fotoLapangan,
      fasilitas: List<String>.from(data['fasilitas'] ?? []),
      statusVerifikasi: data['status_verifikasi'],
    );
  }

  // Konversi dari FieldModel ke Map untuk dikirim ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id_lapangan': fieldId,
      'mitraId': mitraId,
      'id_pemilik': mitraId, // backward-compat key
      'nama_venue': namaVenue,
      'nama_lapangan': namaLapangan,
      'kategori_lapangan': kategori,
      'harga_sewa_jam': hargaPerJam,
      'alamat_lengkap': alamat,
      'location': GeoPoint(latitude, longitude),
      'deskripsi_fasilitas': deskripsi,
      'is_aktif': isAktif,
      'avg_rating': ratingAvg,
      'total_ulasan': totalUlasan,
      'foto_lapangan': fotoGaleri,
      'fasilitas': fasilitas,
      'status_verifikasi': statusVerifikasi,
    };
  }
}
