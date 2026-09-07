import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../datasources/order_local_datasource.dart';

class OfflineSyncService {
  final OrderLocalDataSourceImpl orderDataSource;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  OfflineSyncService({
    required this.orderDataSource,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  Future<void> start() async {
    await _syncIfOnline(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen(_syncIfOnline);
  }

  Future<void> _syncIfOnline(List<ConnectivityResult> results) async {
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    await orderDataSource.syncPendingOperations(isOnline: isOnline);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
