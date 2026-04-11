import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  });
  Future<void> logout();
  Future<void>sendPasswordResetEmail(String email);
  Stream<UserEntity?> get authStateChanges;
}
