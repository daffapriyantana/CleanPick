import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final bool embedded;
  const ProfilePage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthSuccess ? state.user : null;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!embedded) const SizedBox.shrink(),
              if (embedded)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Profil',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        child:
                            Icon(Icons.person, color: Colors.white, size: 40)),
                    const SizedBox(height: 12),
                    Text(user?.name ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(user?.email ?? '-',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    _tile(Icons.phone_outlined, 'Nomor HP', user?.phone ?? '-'),
                    const Divider(height: 1),
                    _tile(Icons.home_outlined, 'Alamat', user?.address ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit Profil'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Fitur edit profil segera hadir')),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.error),
                      title: const Text('Logout',
                          style: TextStyle(color: AppColors.error)),
                      onTap: () async {
                        await context.read<AuthCubit>().logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('Profil')), body: body);
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      subtitle:
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
