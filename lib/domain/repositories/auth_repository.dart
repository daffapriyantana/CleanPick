import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> signInWithGoogle();
  Future<void> resetPassword({required String email});
  Future<UserEntity> loginPetugas(
      {required String id, required String password});

  Future<UserEntity> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  });
  Future<UserEntity> registerPetugas({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> logout();

  UserEntity? get currentUser;
  String? get currentRole;
}
