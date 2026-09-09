import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import 'customer_profile_pages.dart';
import 'customer_support_pages.dart';
import 'login_page.dart';

class PetugasProfilePage extends StatefulWidget {
  const PetugasProfilePage({super.key});

  @override
  State<PetugasProfilePage> createState() => _PetugasProfilePageState();
}

class _PetugasProfilePageState extends State<PetugasProfilePage> {
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;
    final name =
        user?.name.trim().isNotEmpty == true ? user!.name : 'Ahmad Supardi';
    final employeeId =
        user?.id.trim().isNotEmpty == true ? user!.id : 'PTG-001';

    return ColoredBox(
      color: const Color(0xFFF8FAF9),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              _ProfileHeader(name: name, employeeId: employeeId),
              Transform.translate(
                offset: const Offset(0, -12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _WorkStatusCard(
                        isAvailable: _isAvailable,
                        onChanged: (value) =>
                            setState(() => _isAvailable = value),
                      ),
                      const SizedBox(height: 14),
                      _ProfileMenuCard(
                        onVehicles: () => _showPlaceholder(
                            'Halaman Kendaraan Saya segera tersedia'),
                        onHistory: () => _showPlaceholder(
                            'Riwayat Pesanan tersedia pada menu Pesanan'),
                        onNotifications: () => _showPlaceholder(
                            'Pengaturan notifikasi segera tersedia'),
                        onHelp: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const HelpFaqPage()),
                        ),
                        onTerms: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CustomerInfoPage(
                              title: 'Syarat & Ketentuan',
                              content:
                                  'Gunakan aplikasi CleanPick sesuai prosedur operasional. Pastikan status pickup dan data pesanan diperbarui dengan benar.',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton.icon(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Keluar dari Akun'),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF1F2),
                            foregroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'CleanPick Petugas v1.0.0',
                        style:
                            TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;
    await context.read<AuthCubit>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String employeeId;
  const _ProfileHeader({required this.name, required this.employeeId});

  @override
  Widget build(BuildContext context) => Container(
        height: 182,
        width: double.infinity,
        color: AppColors.primaryDark,
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFD9F4E3),
              child: Icon(Icons.person, color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text('4.8 / 5.0',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Nomor ID: $employeeId',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      );
}

class _WorkStatusCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;
  const _WorkStatusCard({required this.isAvailable, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F7ED),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.power_settings_new,
                  color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status Kerja',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Sedang bersiap menerima order',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
            Switch(value: isAvailable, onChanged: onChanged),
          ],
        ),
      );
}

class _ProfileMenuCard extends StatelessWidget {
  final VoidCallback onVehicles;
  final VoidCallback onHistory;
  final VoidCallback onNotifications;
  final VoidCallback onHelp;
  final VoidCallback onTerms;

  const _ProfileMenuCard({
    required this.onVehicles,
    required this.onHistory,
    required this.onNotifications,
    required this.onHelp,
    required this.onTerms,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _item(Icons.local_shipping_outlined, 'Kendaraan Saya', onVehicles),
            _divider(),
            _item(Icons.history, 'Riwayat Pesanan', onHistory),
            _divider(),
            _item(Icons.notifications_none, 'Pengaturan Notifikasi',
                onNotifications),
            _divider(),
            _item(Icons.help_outline, 'Bantuan', onHelp),
            _divider(),
            _item(Icons.description_outlined, 'Syarat & Ketentuan', onTerms),
          ],
        ),
      );

  Widget _divider() => const Divider(height: 1, indent: 54);

  Widget _item(IconData icon, String title, VoidCallback onTap) => SizedBox(
        height: 52,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Icon(icon, color: AppColors.primary, size: 21),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 19),
        ),
      );
}
