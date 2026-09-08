import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class FindingOfficerPage extends StatefulWidget {
  const FindingOfficerPage({super.key});

  @override
  State<FindingOfficerPage> createState() => _FindingOfficerPageState();
}

class _FindingOfficerPageState extends State<FindingOfficerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mencari Petugas')),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Column(
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 5),
                  const Text('Mohon tunggu sebentar',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Batalkan'),
              ),
            ],
          ),
        ),
      );
}
