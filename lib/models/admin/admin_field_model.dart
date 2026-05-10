import 'package:lapangku/models/field/base_field_model.dart';

class AdminFieldModel extends BaseFieldModel {
  final String namaMitra;
  final String emailPemilik;
  final String lokasi;
  final String jenis;
  final String statusVerifikasi;
  final DateTime? createdAt;

  const AdminFieldModel({
    required String fieldId,
    required String mitraId,
    required String namaLapangan,
    required this.namaMitra,
    required this.emailPemilik,
    required this.lokasi,
    required int hargaPerJam,
    required this.jenis,
    required this.statusVerifikasi,
    this.createdAt,
  }) : super(
          fieldId: fieldId,
          mitraId: mitraId,
          namaVenue: '',
          namaLapangan: namaLapangan,
          hargaPerJam: hargaPerJam,
        );

  /// Backward-compat getter: tetap bisa akses .mitraUid
  String get mitraUid => mitraId;
}
