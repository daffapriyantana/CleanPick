import '../../core/error/failures.dart';
import '../../core/utils/validators.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  const RegisterUseCase(this.repository);

  Future<UserEntity> call({
    required String name,
    required String email,
    required String phone,
    required String address,
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
    if (Validators.addressError(address) != null) {
      throw ValidationFailure(Validators.addressError(address)!);
    }
    if (Validators.passwordError(password) != null) {
      throw ValidationFailure(Validators.passwordError(password)!);
    }
    if (Validators.confirmPasswordError(password, confirmPassword) != null) {
      throw ValidationFailure(Validators.confirmPasswordError(password, confirmPassword)!);
    }

    return repository.register(
      name: name,
      email: email,
      phone: phone,
      address: address,
      password: password,
    );
  }
}
