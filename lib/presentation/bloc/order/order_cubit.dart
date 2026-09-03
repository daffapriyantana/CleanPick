import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../domain/usecases/calculate_order_price.dart';
import '../../../domain/usecases/cancel_order.dart';
import '../../../domain/usecases/create_order.dart';
import '../../../domain/usecases/get_order_detail.dart';
import '../../../domain/usecases/get_orders.dart';
import '../../../domain/usecases/pay_order.dart';
import 'order_state.dart';

/// The Cubit that drives the whole "Pesanan" feature -- this is the
/// state management the milestone asks to be prioritised.
///
/// Flow for every action: Loading -> (Success state) | OrderFailure,
/// exactly as described in the spec's sequence diagram.
class OrderCubit extends Cubit<OrderState> {
  final GetOrders getOrders;
  final GetOrderDetail getOrderDetail;
  final CreateOrder createOrder;
  final CancelOrder cancelOrder;
  final PayOrder payOrder;
  final CalculateOrderPrice calculatePrice;

  OrderCubit({
    required this.getOrders,
    required this.getOrderDetail,
    required this.createOrder,
    required this.cancelOrder,
    required this.payOrder,
    CalculateOrderPrice? calculatePrice,
  })  : calculatePrice = calculatePrice ?? const CalculateOrderPrice(),
        super(const OrderInitial());

  Future<void> loadOrders() async {
    emit(const OrderLoading());
    try {
      final orders = await getOrders();
      emit(OrdersLoaded(orders));
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
    } catch (e) {
      emit(OrderFailure('Gagal memuat pesanan: $e'));
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    emit(const OrderLoading());
    try {
      final order = await getOrderDetail(orderId);
      emit(OrderDetailLoaded(order));
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
    } catch (e) {
      emit(OrderFailure('Gagal memuat detail pesanan: $e'));
    }
  }

  /// Recalculates the live estimate shown on "Buat Pesanan" without
  /// hitting the repository -- pure domain logic, instant feedback.
  void previewPrice({
    required double weightKg,
    required WasteType wasteType,
    required VehicleType vehicleType,
  }) {
    try {
      final result = calculatePrice(
        weightKg: weightKg,
        wasteType: wasteType,
        vehicleType: vehicleType,
      );
      emit(OrderPricePreview(result));
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
    }
  }

  Future<void> submitOrder({
    required WasteType? wasteType,
    required double weightKg,
    required String address,
    required DateTime? pickupDate,
    required VehicleType vehicleType,
    String? note,
  }) async {
    emit(const OrderLoading());
    try {
      final order = await createOrder(
        wasteType: wasteType,
        weightKg: weightKg,
        address: address,
        pickupDate: pickupDate,
        vehicleType: vehicleType,
        note: note,
      );
      emit(OrderCreated(order));
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
    } catch (e) {
      emit(OrderFailure('Gagal membuat pesanan: $e'));
    }
  }

  Future<void> cancel(String orderId) async {
    emit(const OrderLoading());
    try {
      final order = await cancelOrder(orderId);
      emit(OrderCancelled(order));
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
    } catch (e) {
      emit(OrderFailure('Gagal membatalkan pesanan: $e'));
    }
  }

  Future<void> pay(String orderId) async {
    emit(const OrderLoading());
    try {
      final order = await payOrder(orderId);
      emit(OrderPaid(order));
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
    } catch (e) {
      emit(OrderFailure('Gagal memproses pembayaran: $e'));
    }
  }
}
