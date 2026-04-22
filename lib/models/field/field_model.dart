import 'package:cloud_firestore/cloud_firestore.dart';

class FieldModel {
  final String id;
  final String idLapangan;
  final String nama;
  final String kategori;
  final int hargaPerJam;
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
  final String idPemilik;
  final String? statusVerifikasi;

  const FieldModel({
    required this.id,
    this.idLapangan = '',
    required this.nama,
    required this.kategori,
    required this.hargaPerJam,
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
    required this.idPemilik,
    this.statusVerifikasi,
  });

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
      idLapangan: data['id_lapangan'] ?? '',
      nama: data['nama_lapangan'] ?? '',
      kategori: data['kategori_lapangan'] ?? '',
      hargaPerJam: (data['harga_sewa_jam'] ?? 0).toInt(),
      alamat: data['alamat_lengkap'] ?? '',
      latitude: lat,
      longitude: lng,
      deskripsi: data['deskripsi_fasilitas'] ?? '',
      isAktif: data['is_aktif'] ?? true,
      ratingAvg: (data['avg_rating'] ?? 0).toDouble(),
      totalUlasan: (data['total_ulasan'] ?? 0).toInt(),
      fotoUtama: fotoLapangan.isNotEmpty ? fotoLapangan.first : '',
      fotoGaleri: fotoLapangan,
      fasilitas: List<String>.from(data['fasilitas'] ?? []),
      idPemilik: data['id_pemilik'] ?? '',
      statusVerifikasi: data['status_verifikasi'],
    );
  }

  // Konversi dari FieldModel ke Map untuk dikirim ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id_lapangan': idLapangan,
      'nama_lapangan': nama,
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
      'id_pemilik': idPemilik,
      'status_verifikasi': statusVerifikasi,
    };
  }
}
