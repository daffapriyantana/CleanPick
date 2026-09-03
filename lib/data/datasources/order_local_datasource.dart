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
  Future<OrderModel> cancelOrder(String orderId);
  Future<OrderModel> payOrder(String orderId);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  /// In-memory "database", seeded with dummy data per the spec so the
  /// app is demoable without any backend.
  final List<OrderModel> _orders = [
    OrderModel(
      id: 'CP-20240115-001',
      wasteType: WasteType.organik,
      weightKg: 10,
      address: 'Jl. Melati No. 12, RT 05/RW 03, Kel. Kebayoran Baru, Jakarta Selatan',
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
      address: 'Jl. Melati No. 12, RT 05/RW 03, Kel. Kebayoran Baru, Jakarta Selatan',
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

  @override
  Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 600));
    // newest first
    final sorted = List<OrderModel>.from(_orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<OrderModel> getOrderDetail(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 900));
    _orders.add(order);
    return order;
  }

  @override
  Future<OrderModel> cancelOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
    }
    final updated = OrderModel.fromEntity(
      _orders[index].copyWith(status: OrderStatus.dibatalkan),
    );
    _orders[index] = updated;
    return updated;
  }

  @override
  Future<OrderModel> payOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
    }
    final updated = OrderModel.fromEntity(
      _orders[index].copyWith(paymentStatus: PaymentStatus.lunas),
    );
    _orders[index] = updated;
    return updated;
  }
}
