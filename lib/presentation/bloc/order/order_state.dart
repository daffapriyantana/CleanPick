import 'package:equatable/equatable.dart';

import '../../../domain/entities/order_entity.dart';
import '../../../domain/entities/payment_checkout.dart';
import '../../../domain/usecases/calculate_order_price.dart';

/// All states the "Pesanan" feature can be in. Kept in one hierarchy
/// (rather than one class per use case) because the spec explicitly
/// asks for a minimal Initial / Loading / Success / Failure shape.
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

/// Emitted after [OrderCubit.loadOrders] succeeds.
class OrdersLoaded extends OrderState {
  final List<OrderEntity> orders;
  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

/// Emitted after [OrderCubit.loadOrderDetail] succeeds.
class OrderDetailLoaded extends OrderState {
  final OrderEntity order;
  const OrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

/// Emitted right after a new order is created, so the "Buat Pesanan"
/// page can navigate to a confirmation/detail screen.
class OrderCreated extends OrderState {
  final OrderEntity order;
  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

/// Emitted while the user is adjusting inputs on "Buat Pesanan" so the
/// estimated cost card can update live, before the order is submitted.
class OrderPricePreview extends OrderState {
  final OrderPriceResult price;
  const OrderPricePreview(this.price);

  @override
  List<Object?> get props => [price];
}

class OrderCancelled extends OrderState {
  final OrderEntity order;
  const OrderCancelled(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderPaid extends OrderState {
  final OrderEntity order;
  const OrderPaid(this.order);

  @override
  List<Object?> get props => [order];
}

class PaymentCheckoutReady extends OrderState {
  final OrderEntity order;
  final PaymentCheckout checkout;

  const PaymentCheckoutReady(this.order, this.checkout);

  @override
  List<Object?> get props => [order, checkout];
}

class OrderFailure extends OrderState {
  final String message;
  const OrderFailure(this.message);

  @override
  List<Object?> get props => [message];
}
