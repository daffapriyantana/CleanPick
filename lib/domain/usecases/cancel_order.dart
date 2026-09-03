import '../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class CancelOrder {
  final OrderRepository repository;
  const CancelOrder(this.repository);

  Future<OrderEntity> call(String orderId) {
    if (orderId.trim().isEmpty) {
      throw const ValidationFailure('ID pesanan tidak valid');
    }
    return repository.cancelOrder(orderId);
  }
}
