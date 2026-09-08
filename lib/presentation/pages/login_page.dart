import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../widgets/custom_text_field.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'petugas_login_page.dart';
import 'admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'budi@email.com');
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            } else if (state is AuthPasswordResetSent) {
              _showMessage(
                'Email reset password telah dikirim. Periksa inbox Anda.',
              );
            } else if (state is AuthFailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.recycling,
                            color: AppColors.primary, size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('CleanPick',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    const Text('Selamat Datang Kembali',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const Text('Silakan masuk untuk melanjutkan pesanan Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 28),
                    CustomTextField(
                      label: 'Email',
                      hint: 'contoh: budi@gmail.com',
                      controller: _emailController,
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.emailError,
                    ),
                    CustomTextField(
                      label: 'Password',
                      hint: 'Masukkan password Anda',
                      controller: _passwordController,
                      obscureText: _obscure,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: Validators.passwordError,
                    ),
                    Row(
                      children: [
                        SizedBox(
                          height: 28,
                          width: 28,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value ?? false),
                            activeColor: AppColors.primary,
                          ),
                        ),
                        const Text('Ingat Saya',
                            style: TextStyle(fontSize: 12)),
                        const Spacer(),
                        TextButton(
                          onPressed: isLoading ? null : _resetPassword,
                          child: const Text('Lupa Password?',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthCubit>().login(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _showMessage('Login Google belum tersedia'),
                      icon: const Icon(Icons.g_mobiledata, size: 22),
                      label: const Text('Masuk dengan Google'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const PetugasLoginPage()),
                                    ),
                            child: const Text('Masuk sebagai Petugas',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const AdminDashboardPage()),
                                    ),
                            child: const Text('Masuk sebagai Admin',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun? ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage()),
                          ),
                          child: const Text('Daftar',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text('Demo: budi@email.com / password123',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetPassword() {
    final email = _emailController.text.trim();
    if (Validators.emailError(email) != null) {
      _showMessage(Validators.emailError(email)!);
      return;
    }

    context.read<AuthCubit>().resetPassword(email: email);
  }
}
