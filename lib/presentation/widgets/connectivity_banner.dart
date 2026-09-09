import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _readInitialConnection();
  }

  Future<void> _readInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isOnline = results.any((result) => result != ConnectivityResult.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data;
        final offline = results == null
            ? !_isOnline
            : results.every((result) => result == ConnectivityResult.none);
        return Container(
          width: double.infinity,
          color: offline ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            offline
                ? 'Koneksi internet terputus. Sesi tetap dapat digunakan; '
                    'beberapa fitur membutuhkan koneksi.'
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

class ConnectionStatusIndicator extends StatefulWidget {
  final Color foregroundColor;

  const ConnectionStatusIndicator({
    super.key,
    this.foregroundColor = Colors.white,
  });

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _readInitialConnection();
  }

  Future<void> _readInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isOnline = results.any((result) => result != ConnectivityResult.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data;
        final online = results == null
            ? _isOnline
            : results.any((result) => result != ConnectivityResult.none);
        final color =
            online ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              online ? 'ONLINE' : 'DISCONNECTED',
              style: TextStyle(
                color: online ? widget.foregroundColor : color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ],
        );
      },
    );
  }
}
