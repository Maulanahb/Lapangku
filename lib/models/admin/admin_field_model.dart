import 'package:lapangku/models/field/base_field_model.dart';

class AdminFieldModel extends BaseFieldModel {
  final String namaMitra;
  final String emailPemilik;
  final String lokasi;
  final String jenis;
  final String statusVerifikasi;
  final DateTime? createdAt;
  final List<String>? photoUrls;
  final String phone;
  final String deskripsi;
  final String tipeLapangan;
  final List<String> fasilitas;
  final String jamOperasional;
  final List<String> hariOperasional;
  final String? ktpUrl;
  final String? selfieUrl;

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
    this.photoUrls,
    this.phone = '',
    this.deskripsi = '',
    this.tipeLapangan = '',
    this.fasilitas = const [],
    this.jamOperasional = '',
    this.hariOperasional = const [],
    this.ktpUrl,
    this.selfieUrl,
  }) : super(
          namaVenue: '',
        );

  /// Backward-compat getter: tetap bisa akses .mitraUid
  String get mitraUid => mitraId;
}
