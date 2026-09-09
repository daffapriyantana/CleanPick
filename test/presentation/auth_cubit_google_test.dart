import 'package:flutter_test/flutter_test.dart';

import 'package:cleanpick/core/error/failures.dart';
import 'package:cleanpick/domain/entities/user_entity.dart';
import 'package:cleanpick/domain/repositories/auth_repository.dart';
import 'package:cleanpick/domain/usecases/login_usecase.dart';
import 'package:cleanpick/domain/usecases/register_usecase.dart';
import 'package:cleanpick/presentation/bloc/auth/auth_cubit.dart';
import 'package:cleanpick/presentation/bloc/auth/auth_state.dart';

class _FakeAuthRepository implements AuthRepository {
  final UserEntity user = const UserEntity(
    id: 'google-uid',
    name: 'Google User',
    email: 'google@example.com',
    phone: '',
    address: '',
  );
  bool googleShouldFail = false;
  bool emailLoginCalled = false;

  @override
  UserEntity? get currentUser => null;

  @override
  String? get currentRole => null;

  @override
  Future<UserEntity> login(
      {required String email, required String password}) async {
    emailLoginCalled = true;
    return user;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    if (googleShouldFail) {
      throw const AuthFailure('Login dengan Google dibatalkan');
    }
    return user;
  }

  @override
  Future<UserEntity> loginPetugas(
          {required String id, required String password}) async =>
      user;

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async =>
      user;

  @override
  Future<UserEntity> registerPetugas({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async =>
      user;

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> logout() async {}
}

AuthCubit _createCubit(_FakeAuthRepository repository) => AuthCubit(
      loginUseCase: LoginUseCase(repository),
      loginPetugasUseCase: LoginPetugasUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      registerPetugasUseCase: RegisterPetugasUseCase(repository),
      resetPasswordUseCase: ResetPasswordUseCase(repository),
      repository: repository,
    );

void main() {
  test('Google sign-in success emits authenticated user', () async {
    final repository = _FakeAuthRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    await cubit.signInWithGoogle();

    expect(cubit.state, isA<AuthSuccess>());
    expect((cubit.state as AuthSuccess).user.email, 'google@example.com');
  });

  test('Google sign-in failure emits a user-facing auth error', () async {
    final repository = _FakeAuthRepository()..googleShouldFail = true;
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    await cubit.signInWithGoogle();

    expect(cubit.state, isA<AuthFailureState>());
    expect((cubit.state as AuthFailureState).message,
        'Login dengan Google dibatalkan');
  });

  test('email/password login path remains available', () async {
    final repository = _FakeAuthRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    await cubit.login(email: 'google@example.com', password: 'password');

    expect(repository.emailLoginCalled, isTrue);
    expect(cubit.state, isA<AuthSuccess>());
  });
}
