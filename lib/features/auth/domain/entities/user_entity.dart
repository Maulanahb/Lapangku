class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String role; //customer,mitra,admin
  final String? phone;
  final String? photoUrl;
  final String? statusVerifikasi; //khusu mitra

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.photoUrl,
    this.statusVerifikasi,
  });
}
