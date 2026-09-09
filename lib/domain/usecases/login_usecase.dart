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

class RegisterPetugasUseCase {
  final AuthRepository repository;
  const RegisterPetugasUseCase(this.repository);

  Future<UserEntity> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    if (Validators.nameError(name) != null) {
      throw ValidationFailure(Validators.nameError(name)!);
    }
    if (Validators.emailError(email) != null) {
      throw ValidationFailure(Validators.emailError(email)!);
    }
    if (Validators.phoneError(phone) != null) {
      throw ValidationFailure(Validators.phoneError(phone)!);
    }
    if (Validators.passwordError(password) != null) {
      throw ValidationFailure(Validators.passwordError(password)!);
    }
    if (Validators.confirmPasswordError(password, confirmPassword) != null) {
      throw ValidationFailure(
          Validators.confirmPasswordError(password, confirmPassword)!);
    }

    return repository.registerPetugas(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }
}

class ResetPasswordUseCase {
  final AuthRepository repository;
  const ResetPasswordUseCase(this.repository);

  Future<void> call({required String email}) async {
    if (email.trim().isEmpty) {
      throw const ValidationFailure('Email wajib diisi');
    }
    if (!Validators.isValidEmail(email)) {
      throw const ValidationFailure('Format email tidak valid');
    }
    return repository.resetPassword(email: email);
  }
}
