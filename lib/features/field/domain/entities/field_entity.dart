class FieldEntity {
  final String id;
  final String idLapangan; // new
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
  final String? statusVerifikasi; // new

  const FieldEntity({
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
}