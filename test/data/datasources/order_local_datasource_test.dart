import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanpick/core/constants/app_constants.dart';
import 'package:cleanpick/data/datasources/order_local_datasource.dart';
import 'package:cleanpick/data/models/order_model.dart';

OrderModel _order({String syncStatus = 'synced'}) => OrderModel(
      id: 'CP-OFFLINE-001',
      wasteType: WasteType.organik,
      weightKg: 10,
      address: 'Jl. Offline No. 1',
      pickupDate: DateTime(2026, 9, 9),
      vehicleType: VehicleType.pickup,
      baseFee: 35000,
      distanceFee: 0,
      weightFee: 20000,
      totalPrice: 55000,
      status: OrderStatus.menunggu,
      paymentStatus: PaymentStatus.belumBayar,
      createdAt: DateTime(2026, 9, 9),
      syncStatus: syncStatus,
    );

void main() {
  test('OrderModel mempertahankan metadata syncStatus saat serialisasi', () {
    final pending = _order(syncStatus: 'pending');

    final restored = OrderModel.fromJson(pending.toJson());

    expect(restored.id, pending.id);
    expect(restored.syncStatus, 'pending');
  });

  test('OrderLocalDataSource menyimpan cache dan queue secara persistent',
      () async {
    SharedPreferences.setMockInitialValues({
      'cleanpick_orders_cache': '[]',
    });
    final preferences = await SharedPreferences.getInstance();
    final firstSource = OrderLocalDataSourceImpl(preferences: preferences);

    await firstSource.createOrder(_order(syncStatus: 'pending'));

    final secondSource = OrderLocalDataSourceImpl(preferences: preferences);
    final cached = await secondSource.getOrders();

    expect(cached, hasLength(1));
    expect(cached.single.id, 'CP-OFFLINE-001');
    expect(await secondSource.readPendingOperationCount(), 1);

    expect(
      await secondSource.syncPendingOperations(isOnline: false),
      1,
    );
    expect(await secondSource.readPendingOperationCount(), 1);
  });

  test('OrderLocalDataSource memulihkan fallback saat cache corrupt', () async {
    SharedPreferences.setMockInitialValues({
      'cleanpick_orders_cache': '{invalid-json',
    });
    final preferences = await SharedPreferences.getInstance();
    final source = OrderLocalDataSourceImpl(preferences: preferences);

    final orders = await source.getOrders();

    expect(orders, hasLength(2));
    expect(preferences.getString('cleanpick_orders_cache'), isNot('{invalid-json'));
  });
}
