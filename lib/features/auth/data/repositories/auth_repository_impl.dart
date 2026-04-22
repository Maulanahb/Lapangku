import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _datasource = AuthRemoteDatasource();

  @override
  Future<UserEntity> login(String email, String password) async {
    final user = await _datasource.login(email, password);
    final data = await _datasource.getUserData(user.uid);
    return _toEntity(data);
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    final user = await _datasource.register(
      email: email,
      password: password,
      nama: name,
      phone: phone,
      role: role,
    );
    final data = await _datasource.getUserData(user.uid);
    return _toEntity(data);
  }

  @override
  Future<void> logout() => _datasource.logout();

  @override
  Future<void> sendPasswordReset(String email) =>
      _datasource.sendPasswordReset(email);

  @override
  Stream<UserEntity?> get authStateChanges {
    return _datasource.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      final data = await _datasource.getUserData(user.uid);
      return _toEntity(data);
    });
  }

  UserEntity _toEntity(Map<String, dynamic> data) {
    return UserEntity(
      uid: data['uid']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      // Parameter di UserEntity diubah dari 'name' menjadi 'nama'
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
}