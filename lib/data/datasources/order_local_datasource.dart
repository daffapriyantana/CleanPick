import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../models/order_model.dart';

/// Contract for wherever order data physically lives. Today it is
/// backed by an in-memory list; tomorrow a [OrderRemoteDataSource]
/// implementing the same interface could hit Firebase/REST without
/// the repository (or anything above it) needing to change.
abstract class OrderLocalDataSource {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> getOrderDetail(String orderId);
  Future<OrderModel> createOrder(OrderModel order);
  Future<OrderModel> assignOrder(
      {required String orderId, required String officerName});
  Future<OrderModel> cancelOrder(String orderId);
  Future<OrderModel> payOrder(String orderId);
  Future<OrderModel> completeOrder(String orderId) async {
    throw UnimplementedError();
  }
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  static const _ordersKey = 'cleanpick_orders_cache';
  static const _queueKey = 'cleanpick_sync_queue';

  final SharedPreferences? _providedPreferences;
  late final Future<void> _initialization = _restore();

  final List<OrderModel> _orders = [
    OrderModel(
      id: 'CP-20240115-001',
      wasteType: WasteType.organik,
      weightKg: 10,
      address:
          'Jl. Melati No. 12, RT 05/RW 03, Kel. Kebayoran Baru, Jakarta Selatan',
      pickupDate: DateTime.now().subtract(const Duration(days: 5)),
      vehicleType: VehicleType.pickup,
      baseFee: 35000,
      distanceFee: 10000,
      weightFee: 20000,
      totalPrice: 65000,
      status: OrderStatus.selesai,
      paymentStatus: PaymentStatus.lunas,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      officerName: 'Ahmad Supardi',
    ),
    OrderModel(
      id: 'CP-20240120-002',
      wasteType: WasteType.anorganik,
      weightKg: 15,
      address:
          'Jl. Melati No. 12, RT 05/RW 03, Kel. Kebayoran Baru, Jakarta Selatan',
      pickupDate: DateTime.now().add(const Duration(days: 1)),
      vehicleType: VehicleType.motorRoda3,
      baseFee: 25000,
      distanceFee: 10000,
      weightFee: 37500,
      totalPrice: 72500,
      status: OrderStatus.dijadwalkan,
      paymentStatus: PaymentStatus.belumBayar,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      officerName: 'Pak Rudi',
    ),
  ];

  OrderLocalDataSourceImpl({SharedPreferences? preferences})
      : _providedPreferences = preferences;

  Future<SharedPreferences> get _preferences async =>
      _providedPreferences ?? await SharedPreferences.getInstance();

  Future<void> _restore() async {
    final preferences = await _preferences;
    final cachedOrders = preferences.getString(_ordersKey);
    if (cachedOrders == null) {
      await _persistOrders();
      return;
    }
    try {
      final decoded = jsonDecode(cachedOrders) as List<dynamic>;
      _orders
        ..clear()
        ..addAll(decoded
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>)));
    } catch (_) {
      await _persistOrders();
    }
  }

  Future<void> _persistOrders() async {
    final preferences = await _preferences;
    await preferences.setString(
      _ordersKey,
      jsonEncode(_orders.map((order) => order.toJson()).toList()),
    );
  }

  Future<void> _enqueue(String operation, OrderModel order) async {
    final preferences = await _preferences;
    final queue = preferences.getStringList(_queueKey) ?? <String>[];
    queue.add(jsonEncode({'operation': operation, 'order': order.toJson()}));
    await preferences.setStringList(_queueKey, queue);
  }

  int get pendingOperationCount {
    final preferences = _providedPreferences;
    return preferences?.getStringList(_queueKey)?.length ?? 0;
  }

  Future<int> readPendingOperationCount() async {
    await _initialization;
    final preferences = await _preferences;
    return preferences.getStringList(_queueKey)?.length ?? 0;
  }

  Future<int> syncPendingOperations({required bool isOnline}) async {
    await _initialization;
    if (!isOnline) return readPendingOperationCount();
    final preferences = await _preferences;
    final pending = preferences.getStringList(_queueKey)?.length ?? 0;
    await preferences.remove(_queueKey);
    return pending;
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 600));
    // newest first
    final sorted = List<OrderModel>.from(_orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<OrderModel> getOrderDetail(String orderId) async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 900));
    _orders.add(order);
    await _persistOrders();
    await _enqueue('create', order);
    return order;
  }

  @override
  Future<OrderModel> assignOrder(
      {required String orderId, required String officerName}) async {
    await _initialization;
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
    }
    if (_orders[index].status != OrderStatus.menunggu) {
      throw const ServerException('Pesanan sudah diambil petugas lain');
    }
    final updated = OrderModel.fromEntity(
      _orders[index]
          .copyWith(status: OrderStatus.diproses, officerName: officerName),
    );
    _orders[index] = updated;
    await _persistOrders();
    await _enqueue('assign', updated);
    return updated;
  }

  @override
  Future<OrderModel> cancelOrder(String orderId) async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
    }
    final updated = OrderModel.fromEntity(
      _orders[index].copyWith(status: OrderStatus.dibatalkan),
    );
    _orders[index] = updated;
    await _persistOrders();
    await _enqueue('cancel', updated);
    return updated;
  }

  @override
  Future<OrderModel> payOrder(String orderId) async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
    }
    final updated = OrderModel.fromEntity(
      _orders[index].copyWith(paymentStatus: PaymentStatus.lunas),
    );
    _orders[index] = updated;
    await _persistOrders();
    await _enqueue('pay', updated);
    return updated;
  }

  @override
  Future<OrderModel> completeOrder(String orderId) async {
    await _initialization;
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
    }
    final updated = OrderModel.fromEntity(
      _orders[index].copyWith(status: OrderStatus.selesai),
    );
    _orders[index] = updated;
    await _persistOrders();
    await _enqueue('complete', updated);
    return updated;
  }
}
