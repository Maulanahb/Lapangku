class OwnerProfileModel {
  final String id;
  final String businessName;
  final String ownerName;
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

  const OwnerProfileModel({
    required this.id,
    required this.businessName,
    required this.ownerName,
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

  OwnerProfileModel copyWith({
    String? id,
    String? businessName,
    String? ownerName,
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
    return OwnerProfileModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
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
      'ownerName': ownerName,
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

  factory OwnerProfileModel.fromMap(Map<String, dynamic> map, String id) {
    return OwnerProfileModel(
      id: id,
      businessName: map['businessName'] ?? map['namaBisnis'] ?? '',
      ownerName: map['ownerName'] ?? map['nama'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? map['telepon'] ?? '',
      alamat: map['alamat'] ?? '',
      logoUrl: map['logoUrl'] ?? map['fotoLogo'],
      ktpUrl: map['ktpUrl'] ?? map['dokumenKTP'],
      npwpUrl: map['npwpUrl'] ?? map['dokumenNPWP'],
      description: map['description'] ?? '',
      isVerified: map['isVerified'] ?? false,
      totalFields: (map['totalFields'] ?? 0) as int,
      totalOrders: (map['totalOrders'] ?? 0) as int,
      rating: (map['rating'] ?? 0.0).toDouble(),
      notificationOrder: map['notificationOrder'] ?? true,
      notificationPromo: map['notificationPromo'] ?? false,
      bankName: map['bankName'] ?? '',
      bankAccount: map['bankAccount'] ?? '',
    );
  }

  /// Profile kosong untuk owner baru
  factory OwnerProfileModel.empty(String uid) {
    return OwnerProfileModel(
      id: uid,
      businessName: '',
      ownerName: '',
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
