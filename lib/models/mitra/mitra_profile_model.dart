class MitraProfileModel {
  final String id;
  final String businessName;
  final String MitraName;
  final String email;
  final String phone;
  final String alamat;
  final String? logoUrl;
  final String? ktpUrl;
  final String? npwpUrl;
  final String description;
  final bool isVerified;
  final int totalFields;
  final int totalOrders;
  final double rating;
  final bool notificationOrder;
  final bool notificationPromo;
  final String bankName;
  final String bankAccount;

  const MitraProfileModel({
    required this.id,
    required this.businessName,
    required this.MitraName,
    required this.email,
    required this.phone,
    this.alamat = '',
    this.logoUrl,
    this.ktpUrl,
    this.npwpUrl,
    this.description = '',
    required this.isVerified,
    required this.totalFields,
    required this.totalOrders,
    required this.rating,
    required this.notificationOrder,
    required this.notificationPromo,
    required this.bankName,
    required this.bankAccount,
  });

  MitraProfileModel copyWith({
    String? id,
    String? businessName,
    String? MitraName,
    String? email,
    String? phone,
    String? alamat,
    String? logoUrl,
    String? ktpUrl,
    String? npwpUrl,
    String? description,
    bool? isVerified,
    int? totalFields,
    int? totalOrders,
    double? rating,
    bool? notificationOrder,
    bool? notificationPromo,
    String? bankName,
    String? bankAccount,
  }) {
    return MitraProfileModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      MitraName: MitraName ?? this.MitraName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alamat: alamat ?? this.alamat,
      logoUrl: logoUrl ?? this.logoUrl,
      ktpUrl: ktpUrl ?? this.ktpUrl,
      npwpUrl: npwpUrl ?? this.npwpUrl,
      description: description ?? this.description,
      isVerified: isVerified ?? this.isVerified,
      totalFields: totalFields ?? this.totalFields,
      totalOrders: totalOrders ?? this.totalOrders,
      rating: rating ?? this.rating,
      notificationOrder: notificationOrder ?? this.notificationOrder,
      notificationPromo: notificationPromo ?? this.notificationPromo,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'namaBisnis': businessName,
      'MitraName': MitraName,
      'email': email,
      'phone': phone,
      'telepon': phone,
      'alamat': alamat,
      'logoUrl': logoUrl,
      'fotoLogo': logoUrl,
      'ktpUrl': ktpUrl,
      'dokumenKTP': ktpUrl,
      'npwpUrl': npwpUrl,
      'dokumenNPWP': npwpUrl,
      'description': description,
      'isVerified': isVerified,
      'totalFields': totalFields,
      'totalOrders': totalOrders,
      'rating': rating,
      'notificationOrder': notificationOrder,
      'notificationPromo': notificationPromo,
      'bankName': bankName,
      'bankAccount': bankAccount,
    };
  }

  factory MitraProfileModel.fromMap(Map<String, dynamic> map, String id) {
    return MitraProfileModel(
      id: id,
      businessName: map['businessName'] ?? map['namaBisnis'] ?? map['nama_tempat'] ?? '',
      MitraName: map['MitraName'] ?? map['ownerName'] ?? map['nama'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? map['whatsapp'] ?? map['telepon'] ?? '',
      alamat: map['alamat'] ?? '',
      logoUrl: map['logoUrl'] ?? map['fotoLogo'],
      ktpUrl: map['ktpUrl'] ?? map['dokumenKTP'],
      npwpUrl: map['npwpUrl'] ?? map['dokumenNPWP'],
      description: map['description'] ?? map['deskripsi'] ?? '',
      isVerified: map['isVerified'] ?? (map['statusVerifikasi'] == 'aktif'),
      totalFields: (map['totalFields'] ?? 0) as int,
      totalOrders: (map['totalOrders'] ?? 0) as int,
      rating: (map['rating'] ?? 0.0).toDouble(),
      notificationOrder: map['notificationOrder'] ?? true,
      notificationPromo: map['notificationPromo'] ?? false,
      bankName: map['bankName'] ?? '',
      bankAccount: map['bankAccount'] ?? '',
    );
  }

  /// Profile kosong untuk Mitra baru
  factory MitraProfileModel.empty(String uid) {
    return MitraProfileModel(
      id: uid,
      businessName: '',
      MitraName: '',
      email: '',
      phone: '',
      isVerified: false,
      totalFields: 0,
      totalOrders: 0,
      rating: 0.0,
      notificationOrder: true,
      notificationPromo: false,
      bankName: '',
      bankAccount: '',
    );
  }
}
