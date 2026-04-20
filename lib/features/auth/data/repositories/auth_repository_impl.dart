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
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      nama: data['nama'] ?? '',
      role: data['role'] ?? 'customer',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      avatarUrl: data['avatarUrl'],
      bankInfo: data['bankInfo'],
      isVerified: data['isVerified'] ?? false,
      jabatan: data['jabatan'],
      namaBisnis: data['namaBisnis'],
      statusVerifikasi: data['statusVerifikasi'],
    );
  }
}