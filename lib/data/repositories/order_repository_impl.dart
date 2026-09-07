import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/calculate_order_price.dart';
import '../datasources/order_local_datasource.dart';
import '../models/order_model.dart';

/// Concrete implementation of [OrderRepository]. It is the only place
/// that knows the datasource exists, and the only place that
/// translates low-level [Exception]s into domain [Failure]s.
class OrderRepositoryImpl implements OrderRepository {
  final OrderLocalDataSource dataSource;
  final CalculateOrderPrice calculatePrice;
  final Uuid _uuid;

  OrderRepositoryImpl({
    required this.dataSource,
    CalculateOrderPrice? calculatePrice,
    Uuid? uuid,
  })  : calculatePrice = calculatePrice ?? const CalculateOrderPrice(),
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<OrderEntity>> getOrders() async {
    try {
      return await dataSource.getOrders();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<OrderEntity> getOrderDetail(String orderId) async {
    try {
      return await dataSource.getOrderDetail(orderId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<OrderEntity> createOrder({
    required WasteType wasteType,
    required double weightKg,
    required String address,
    required DateTime pickupDate,
    required VehicleType vehicleType,
    String? note,
  }) =>
      createOrderWithDetails(
        wasteType: wasteType,
        weightKg: weightKg,
        address: address,
        pickupDate: pickupDate,
        vehicleType: vehicleType,
        note: note,
      );

  @override
  Future<OrderEntity> createOrderWithDetails({
    required WasteType wasteType,
    required double weightKg,
    required String address,
    required DateTime pickupDate,
    required VehicleType vehicleType,
    String? note,
    String? customerId,
    String? customerName,
    String? photoPath,
    double? latitude,
    double? longitude,
    PaymentMethod paymentMethod = PaymentMethod.codTunai,
    double distanceKm = 0,
  }) async {
    // Business rule (fee calculation) lives in the domain use case;
    // the repository only orchestrates data flow.
    final priceResult = calculatePrice(
      weightKg: weightKg,
      wasteType: wasteType,
      vehicleType: vehicleType,
      distanceKm: distanceKm,
    );

    final order = OrderModel(
      id: 'CP-${_uuid.v4().substring(0, 8).toUpperCase()}',
      wasteType: wasteType,
      weightKg: weightKg,
      address: address,
      pickupDate: pickupDate,
      vehicleType: vehicleType,
      baseFee: priceResult.baseFee,
      distanceFee: priceResult.distanceFee,
      weightFee: priceResult.weightFee,
      totalPrice: priceResult.total,
      status: OrderStatus.menunggu,
      paymentStatus: PaymentStatus.belumBayar,
      createdAt: DateTime.now(),
      note: note,
      customerId: customerId,
      customerName: customerName,
      photoPath: photoPath,
      latitude: latitude,
      longitude: longitude,
      paymentMethod: paymentMethod,
    );

    try {
      return await dataSource.createOrder(order);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<OrderEntity> assignOrder(
      {required String orderId, required String officerName}) async {
    try {
      return await dataSource.assignOrder(
          orderId: orderId, officerName: officerName);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<OrderEntity> cancelOrder(String orderId) async {
    try {
      return await dataSource.cancelOrder(orderId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<OrderEntity> payOrder(String orderId) async {
    try {
      return await dataSource.payOrder(orderId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<OrderEntity> completeOrder(String orderId) async {
    try {
      return await dataSource.completeOrder(orderId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
