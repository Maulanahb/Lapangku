import 'package:lapangku/models/field/base_field_model.dart';

class AdminFieldModel extends BaseFieldModel {
  final String namaMitra;
  final String emailPemilik;
  final String lokasi;
  final String jenis;
  final String statusVerifikasi;
  final DateTime? createdAt;

  const AdminFieldModel({
    required super.fieldId,
    required super.mitraId,
    required super.namaLapangan,
    required this.namaMitra,
    required this.emailPemilik,
    required this.lokasi,
    required super.hargaPerJam,
    required this.jenis,
    required this.statusVerifikasi,
    this.createdAt,
  }) : super(
          namaVenue: '',
        );

  /// Backward-compat getter: tetap bisa akses .mitraUid
  String get mitraUid => mitraId;
}
