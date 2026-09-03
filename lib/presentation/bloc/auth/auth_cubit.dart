import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  AuthCubit({required this.loginUseCase, required this.registerUseCase})
      : super(const AuthInitial());

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

  void logout() {
    emit(const AuthLoggedOut());
  }
}
