class FieldEntity {
  final String fieldId;
  final String ownerUid;
  final String namaLapangan;
  final String namaMitra;
  final String lokasi;
  final int hargaPerJam;
  final String jenis;
  final String statusVerifikasi;

  const FieldEntity({
    required this.fieldId,
    required this.ownerUid,
    required this.namaLapangan,
    required this.namaMitra,
    required this.lokasi,
    required this.hargaPerJam,
    required this.jenis,
    required this.statusVerifikasi,
  });
}