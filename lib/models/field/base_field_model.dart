/// Abstract base class untuk semua model lapangan.
/// Mendefinisikan properti umum yang dimiliki oleh setiap representasi lapangan
/// (Customer View, Mitra View, Admin View).
abstract class BaseFieldModel {
  /// ID unik dokumen di Firestore
  final String fieldId;

  /// ID pemilik lapangan (Mitra UID)
  final String mitraId;

  /// Nama venue / tempat olahraga
  final String namaVenue;

  /// Nama spesifik lapangan (misal: "Lapangan 1", "Court A")
  final String namaLapangan;

  /// Harga sewa per jam dalam Rupiah
  final int hargaPerJam;

  const BaseFieldModel({
    required this.fieldId,
    required this.mitraId,
    this.namaVenue = '',
    required this.namaLapangan,
    required this.hargaPerJam,
  });
}
