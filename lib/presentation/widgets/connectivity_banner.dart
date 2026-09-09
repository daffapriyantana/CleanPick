import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data;
        final offline = results != null &&
            results.every((result) => result == ConnectivityResult.none);
        return Container(
          width: double.infinity,
          color: offline ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            offline
                ? 'Offline - perubahan akan disinkronkan saat koneksi kembali.'
                : 'Koneksi internet tersambung.',
            style: TextStyle(
              fontSize: 12,
              color:
                  offline ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
            ),
          ),
        );
      },
    );
  }
}
