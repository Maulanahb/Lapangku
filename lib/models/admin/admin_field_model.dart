class AdminFieldModel {
  final String fieldId;
  final String mitraUid;
  final String namaLapangan;
  final String namaMitra;
  final String emailPemilik;
  final String lokasi;
  final int hargaPerJam;
  final String jenis;
  final String statusVerifikasi;
  final DateTime? createdAt;

  const AdminFieldModel({
    required this.fieldId,
    required this.mitraUid,
    required this.namaLapangan,
    required this.namaMitra,
    required this.emailPemilik,
    required this.lokasi,
    required this.hargaPerJam,
    required this.jenis,
    required this.statusVerifikasi,
    this.createdAt,
  });
}
