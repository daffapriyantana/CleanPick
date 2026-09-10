import '../entities/payment_checkout.dart';

abstract class PaymentRepository {
  Future<PaymentCheckout> createCheckout(String orderId);
}
