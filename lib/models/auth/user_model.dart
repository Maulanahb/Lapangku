class UserModel {
  final String uid;
  final String email;
  final String nama;
  final String role; // customer, mitra, admin
  final String? phone;
  final String? photoUrl;
  final String? avatarUrl;
  final String? bankInfo;
  final bool isVerified;
  final String? jabatan;
  final String? namaBisnis;
  final String? statusVerifikasi; // khusus mitra

  const UserModel({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
    this.phone,
    this.photoUrl,
    this.avatarUrl,
    this.bankInfo,
    this.isVerified = false,
    this.jabatan,
    this.namaBisnis,
    this.statusVerifikasi,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      nama: data['nama']?.toString() ?? data['name']?.toString() ?? 'User Tanpa Nama',
      role: data['role']?.toString() ?? 'customer',
      phone: data['phone']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      avatarUrl: data['avatarUrl']?.toString() ?? data['photoUrl']?.toString(),
      bankInfo: data['bankInfo']?.toString(),
      isVerified: data['isVerified'] == true,
      jabatan: data['jabatan']?.toString(),
      namaBisnis: data['namaBisnis']?.toString(),
      statusVerifikasi: data['statusVerifikasi']?.toString() ?? 'proses',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'nama': nama,
      'role': role,
      'phone': phone,
      'photoUrl': photoUrl,
      'avatarUrl': avatarUrl,
      'bankInfo': bankInfo,
      'isVerified': isVerified,
      'jabatan': jabatan,
      'namaBisnis': namaBisnis,
      'statusVerifikasi': statusVerifikasi,
    };
  }
}
