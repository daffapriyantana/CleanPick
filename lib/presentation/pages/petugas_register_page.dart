import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../widgets/custom_text_field.dart';

class PetugasRegisterPage extends StatefulWidget {
  const PetugasRegisterPage({super.key});

  @override
  State<PetugasRegisterPage> createState() => _PetugasRegisterPageState();
}

class _PetugasRegisterPageState extends State<PetugasRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agree = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _registerOfficer() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui syarat dan ketentuan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthCubit>().registerPetugas(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          confirmPassword: _confirmController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Petugas'),
        backgroundColor: Colors.white,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.of(context).pop();
          } else if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Buat akun petugas CleanPick',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Nama Petugas',
                    hint: 'contoh: Budi Santoso',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: Validators.nameError,
                  ),
                  CustomTextField(
                    label: 'Email',
                    hint: 'contoh: budi@cleanpick.id',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.emailError,
                  ),
                  CustomTextField(
                    label: 'Nomor HP',
                    hint: 'contoh: 08123456789',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: Validators.phoneError,
                  ),
                  CustomTextField(
                    label: 'Password',
                    hint: 'Buat password baru',
                    controller: _passwordController,
                    obscureText: _obscure1,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                    validator: Validators.passwordError,
                  ),
                  CustomTextField(
                    label: 'Konfirmasi Password',
                    hint: 'Ulangi password baru',
                    controller: _confirmController,
                    obscureText: _obscure2,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                    validator: (v) => Validators.confirmPasswordError(
                      _passwordController.text,
                      v ?? '',
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _agree,
                        onChanged: (v) => setState(() => _agree = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Saya menyetujui syarat dan ketentuan petugas',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: isLoading ? null : _registerOfficer,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Daftar Sebagai Petugas'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
