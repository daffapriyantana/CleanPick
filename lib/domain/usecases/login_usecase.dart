import '../../core/error/failures.dart';
import '../../core/utils/validators.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  const LoginUseCase(this.repository);

  Future<UserEntity> call(
      {required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const ValidationFailure('Email dan password wajib diisi');
    }
    if (!Validators.isValidEmail(email)) {
      throw const ValidationFailure('Format email tidak valid');
    }
    return repository.login(email: email, password: password);
  }
}

class LoginPetugasUseCase {
  final AuthRepository repository;
  const LoginPetugasUseCase(this.repository);

  Future<UserEntity> call(
      {required String id, required String password}) async {
    if (id.trim().isEmpty || password.isEmpty) {
      throw const ValidationFailure('ID petugas dan password wajib diisi');
    }
    return repository.loginPetugas(id: id, password: password);
  }
}
