import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CompleteOrder {
  final OrderRepository repository;
  const CompleteOrder(this.repository);

  Future<OrderEntity> call(String orderId) => repository.completeOrder(orderId);
}
