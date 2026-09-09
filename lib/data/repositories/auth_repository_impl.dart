import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource dataSource;
  const AuthRepositoryImpl({required this.dataSource});

  @override
  Future<UserEntity> login(
      {required String email, required String password}) async {
    try {
      return await dataSource.login(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      return await dataSource.signInWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await dataSource.resetPassword(email: email);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity> loginPetugas(
      {required String id, required String password}) async {
    try {
      return await dataSource.loginPetugas(id: id, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    try {
      return await dataSource.register(
        name: name,
        email: email,
        phone: phone,
        address: address,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity> registerPetugas({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      return await dataSource.registerPetugas(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> logout() => dataSource.logout();

  @override
  UserEntity? get currentUser => dataSource.currentUser;

  @override
  String? get currentRole => dataSource.currentRole;
}
