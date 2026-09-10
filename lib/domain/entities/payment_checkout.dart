import 'package:equatable/equatable.dart';

class PaymentCheckout extends Equatable {
  final String orderId;
  final String snapToken;
  final String redirectUrl;

  const PaymentCheckout({
    required this.orderId,
    required this.snapToken,
    required this.redirectUrl,
  });

  @override
  List<Object?> get props => [orderId, snapToken, redirectUrl];
}
