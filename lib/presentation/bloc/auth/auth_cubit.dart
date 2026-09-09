import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LoginPetugasUseCase loginPetugasUseCase;
  final RegisterUseCase registerUseCase;
  final RegisterPetugasUseCase registerPetugasUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final AuthRepository repository;

  AuthCubit({
    required this.loginUseCase,
    required this.loginPetugasUseCase,
    required this.registerUseCase,
    required this.registerPetugasUseCase,
    required this.resetPasswordUseCase,
    required this.repository,
  }) : super(const AuthInitial());

  Future<String?> restoreSession() async {
    final user = repository.currentUser;
    if (user == null) {
      emit(const AuthLoggedOut());
      return null;
    }
    emit(AuthSuccess(user));
    return repository.currentRole ?? 'customer';
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final user = await loginUseCase(email: email, password: password);
      emit(AuthSuccess(user));
    } on Failure catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Gagal masuk: $e'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final user = await repository.signInWithGoogle();
      emit(AuthSuccess(user));
    } on Failure catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Login dengan Google gagal: $e'));
    }
  }

  Future<void> resetPassword({required String email}) async {
    emit(const AuthLoading());
    try {
      await resetPasswordUseCase(email: email);
      emit(const AuthPasswordResetSent());
    } on Failure catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Gagal mengirim reset password: $e'));
    }
  }

  Future<void> loginPetugas(
      {required String id, required String password}) async {
    emit(const AuthLoading());
    try {
      final user = await loginPetugasUseCase(id: id, password: password);
      emit(AuthSuccess(user));
    } on Failure catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Gagal masuk sebagai petugas: $e'));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
    required String confirmPassword,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await registerUseCase(
        name: name,
        email: email,
        phone: phone,
        address: address,
        password: password,
        confirmPassword: confirmPassword,
      );
      emit(AuthSuccess(user));
    } on Failure catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Gagal mendaftar: $e'));
    }
  }

  Future<void> registerPetugas({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await registerPetugasUseCase(
        name: name,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
      );
      emit(AuthSuccess(user));
    } on Failure catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Gagal mendaftar petugas: $e'));
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();
    } finally {
      emit(const AuthLoggedOut());
    }
  }
}
