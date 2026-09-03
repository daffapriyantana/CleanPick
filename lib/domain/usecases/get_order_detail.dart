import '../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetOrderDetail {
  final OrderRepository repository;
  const GetOrderDetail(this.repository);

  Future<OrderEntity> call(String orderId) {
    if (orderId.trim().isEmpty) {
      throw const ValidationFailure('ID pesanan tidak valid');
    }
    return repository.getOrderDetail(orderId);
  }
}
