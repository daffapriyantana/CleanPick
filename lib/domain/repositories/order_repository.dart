import '../../core/constants/app_constants.dart';
import '../entities/order_entity.dart';

/// Contract the domain layer depends on. The concrete implementation
/// lives in the `data` layer and is free to swap its datasource
/// (in-memory today, Firebase/REST API tomorrow) without this
/// interface -- or any use case -- ever changing.
abstract class OrderRepository {
  Future<List<OrderEntity>> getOrders();

  Future<OrderEntity> getOrderDetail(String orderId);

  Future<OrderEntity> createOrder({
    required WasteType wasteType,
    required double weightKg,
    required String address,
    required DateTime pickupDate,
    required VehicleType vehicleType,
    String? note,
  });

  Future<OrderEntity> createOrderWithDetails({
    required WasteType wasteType,
    required double weightKg,
    required String address,
    required DateTime pickupDate,
    required VehicleType vehicleType,
    String? note,
    String? photoPath,
    double? latitude,
    double? longitude,
    PaymentMethod paymentMethod = PaymentMethod.codTunai,
    double distanceKm = 0,
  }) =>
      createOrder(
        wasteType: wasteType,
        weightKg: weightKg,
        address: address,
        pickupDate: pickupDate,
        vehicleType: vehicleType,
        note: note,
      );

  Future<OrderEntity> cancelOrder(String orderId);

  Future<OrderEntity> payOrder(String orderId);
}
