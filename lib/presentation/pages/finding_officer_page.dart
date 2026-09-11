import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_cubit.dart';

class FindingOfficerPage extends StatefulWidget {
  final String orderId;
  const FindingOfficerPage({super.key, required this.orderId});

  @override
  State<FindingOfficerPage> createState() => _FindingOfficerPageState();
}

class _FindingOfficerPageState extends State<FindingOfficerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _orderSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    context.read<AuthCubit>().notificationService?.watchOrderAssignment(
          widget.orderId,
        );
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data?['status'] == 'diproses' &&
          data?['officerId']?.toString().isNotEmpty == true &&
          mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pencarian tetap berjalan'),
        content: const Text(
          'Pencarian petugas akan berjalan di background. Anda akan mendapat notifikasi saat petugas ditemukan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tetap di sini'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ke belakang'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) => _handleBack(),
        child: Scaffold(
          appBar: AppBar(title: const Text('Mencari Petugas')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Container(
                        width: 112 + (_controller.value * 12),
                        height: 112 + (_controller.value * 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8F7F0),
                          border: Border.all(
                            color: AppColors.primary.withValues(
                                alpha: .25 + (_controller.value * .3)),
                            width: 2,
                          ),
                        ),
                        child: child,
                      ),
                      child: const Icon(Icons.local_shipping_outlined,
                          color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text('Mencari petugas terdekat...',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 5),
                    const Text('Mohon tunggu sebentar',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Halaman ini akan tertutup setelah petugas menerima pesanan.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
              ),
            ),
          ),
        ),
      );
}
