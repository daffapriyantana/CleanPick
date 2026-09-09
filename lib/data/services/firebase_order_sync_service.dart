import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../datasources/firebase_order_datasource.dart';

class FirebaseOrderSyncService {
  final FirebaseOrderDataSource _dataSource;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  FirebaseOrderSyncService({
    required FirebaseOrderDataSource dataSource,
    Connectivity? connectivity,
  })  : _dataSource = dataSource,
        _connectivity = connectivity ?? Connectivity();

  Future<void> start() async {
    await _syncIfOnline(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen(_syncIfOnline);
  }

  Future<void> _syncIfOnline(List<ConnectivityResult> results) async {
    if (results.any((result) => result != ConnectivityResult.none)) {
      await _dataSource.syncPendingOperations();
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
