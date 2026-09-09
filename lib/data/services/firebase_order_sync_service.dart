import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/services/app_event_store.dart';
import '../datasources/firebase_order_datasource.dart';

class FirebaseOrderSyncService {
  final FirebaseOrderDataSource _dataSource;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

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
    if (_isSyncing ||
        !results.any((result) => result != ConnectivityResult.none)) {
      return;
    }

    _isSyncing = true;
    try {
      final synced = await _dataSource.syncPendingOperations();
      if (synced > 0) {
        AppNotificationStore.instance.add(
          title: 'Pesanan Tersinkronisasi',
          message: '$synced pesanan berhasil disinkronkan.',
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
