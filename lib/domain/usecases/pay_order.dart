import '../entities/payment_checkout.dart';
import '../repositories/payment_repository.dart';

class PayOrder {
  final PaymentRepository repository;
  const PayOrder(this.repository);

  Future<PaymentCheckout> call(String orderId) =>
      repository.createCheckout(orderId);
}
