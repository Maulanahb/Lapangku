class UserEntity {
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

  const UserEntity({
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
}
