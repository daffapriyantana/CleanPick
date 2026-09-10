import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../bloc/auth/auth_cubit.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'petugas_dashboard_page.dart';
import 'order_detail_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final role = await context.read<AuthCubit>().restoreSession();
    if (!mounted) return;
    final notificationService = context.read<AuthCubit>().notificationService;
    final pendingRoute = notificationService?.takePendingRoute();
    final navigator = Navigator.of(context);

    if (pendingRoute?.type == 'new_order' && role == 'petugas') {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PetugasDashboardPage(initialTab: 1),
        ),
      );
      return;
    }

    if (pendingRoute?.type == 'order_taken' &&
        pendingRoute?.orderId != null &&
        role == 'customer') {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(orderId: pendingRoute!.orderId!),
          ),
        );
      });
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => role == 'petugas'
            ? const PetugasDashboardPage()
            : role == null
            ? const LoginPage()
            : const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.recycling,
                color: AppColors.primary,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CleanPick',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sampah Diambil, Lingkungan Lebih Bersih.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
