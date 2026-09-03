import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetOrders {
  final OrderRepository repository;
  const GetOrders(this.repository);

  Future<List<OrderEntity>> call() => repository.getOrders();
}
