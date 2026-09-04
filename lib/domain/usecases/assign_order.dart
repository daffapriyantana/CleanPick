import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class AssignOrder {
  final OrderRepository repository;

  const AssignOrder(this.repository);

  Future<OrderEntity> call({required String orderId, required String officerName}) {
    return repository.assignOrder(orderId: orderId, officerName: officerName);
  }
}
