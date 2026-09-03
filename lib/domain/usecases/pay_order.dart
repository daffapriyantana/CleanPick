import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class PayOrder {
  final OrderRepository repository;
  const PayOrder(this.repository);

  Future<OrderEntity> call(String orderId) => repository.payOrder(orderId);
}
