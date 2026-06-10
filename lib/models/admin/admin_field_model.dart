import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory AdminFieldModel.fromMitraDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    String status =
        _readString(data, ['statusVerifikasi'], fallback: 'menunggu')
            .toLowerCase()
            .trim();
    if (!data.containsKey('statusVerifikasi')) {
      status = data['isVerified'] == true ? 'aktif' : 'menunggu';
    }

    return AdminFieldModel(
      fieldId: doc.id,
      mitraId: _readString(
        data,
        ['uid', 'mitraId', 'MitraId', 'id_pemilik'],
        fallback: doc.id,
      ),
      namaLapangan: _readString(
        data,
        ['namaLapangan', 'nama_lapangan', 'businessName', 'namaBisnis', 'name'],
        fallback: 'Bisnis Baru',
      ),
      namaMitra: _readString(
        data,
        ['ownerName', 'MitraName', 'mitraName', 'nama', 'namaPemilik'],
        fallback: 'Mitra',
      ),
      emailPemilik: _readString(data, ['email'], fallback: ''),
      lokasi: _readString(
        data,
        ['alamat', 'alamat_lengkap', 'address'],
        fallback: 'Alamat belum diatur',
      ),
      hargaPerJam: _readInt(
        data,
        ['hargaPerJam', 'harga_sewa_jam', 'pricePerHour', 'hargaSewaJam'],
      ),
      jenis: _readString(
        data,
        ['sport', 'jenisLapangan', 'kategori_lapangan'],
        fallback: '',
      ),
      statusVerifikasi: status,
      createdAt: _readDateTime(data['createdAt']) ?? DateTime.now(),
      photoUrls: _readStringList(data, ['photoUrls', 'photos', 'images']),
      phone: _readString(data, ['phone', 'noHp', 'phoneNumber']),
      deskripsi: _readString(data, ['deskripsi', 'deskripsi_fasilitas']),
      tipeLapangan: _readString(data, ['tipeLapangan', 'tipe_lapangan']),
      fasilitas: _readStringList(data, ['fasilitas', 'facilities']),
      jamOperasional: _readJamOperasional(data),
      hariOperasional: _readStringList(data, ['hariOperasional']),
      ktpUrl: _readNullableString(data, ['ktpUrl']),
      selfieUrl: _readNullableString(data, ['selfieUrl']),
    );
  }

  /// Backward-compat getter: tetap bisa akses .mitraUid
  String get mitraUid => mitraId;
}

String _readString(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}

String? _readNullableString(Map<String, dynamic> data, List<String> keys) {
  final value = _readString(data, keys);
  return value.isEmpty ? null : value;
}

int _readInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final parsed = _toInt(data[key]);
    if (parsed != null) return parsed;
  }
  return 0;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final cleaned = value.toString().replaceAll(RegExp(r'[^0-9-]'), '');
  if (cleaned.isEmpty || cleaned == '-') return null;
  return int.tryParse(cleaned);
}

DateTime? _readDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

List<String> _readStringList(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is Iterable) {
      return value.map((e) => e.toString()).toList();
    }
  }
  return [];
}

String _readJamOperasional(Map<String, dynamic> data) {
  final explicit = _readString(data, ['jamOperasional']);
  if (explicit.isNotEmpty) return explicit;

  final jamBuka = _readString(data, ['jamBuka']);
  final jamTutup = _readString(data, ['jamTutup']);
  if (jamBuka.isNotEmpty && jamTutup.isNotEmpty) {
    return '$jamBuka - $jamTutup';
  }
  return '';
}
