import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../domain/usecases/calculate_order_price.dart';
import '../../../domain/usecases/cancel_order.dart';
import '../../../domain/usecases/assign_order.dart';
import '../../../domain/usecases/complete_order.dart';
import '../../../domain/usecases/create_order.dart';
import '../../../domain/usecases/get_order_detail.dart';
import '../../../domain/usecases/get_orders.dart';
import '../../../domain/usecases/pay_order.dart';
import 'order_state.dart';
import '../../../core/services/app_event_store.dart';

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
  final AssignOrder assignOrder;
  final CompleteOrder completeOrder;
  final CalculateOrderPrice calculatePrice;

  OrderCubit({
    required this.getOrders,
    required this.getOrderDetail,
    required this.createOrder,
    required this.cancelOrder,
    required this.payOrder,
    required this.assignOrder,
    required this.completeOrder,
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
    List<WasteType>? wasteTypes,
    required VehicleType vehicleType,
    double distanceKm = 0,
  }) {
    try {
      final result = calculatePrice(
        weightKg: weightKg,
        wasteType: wasteType,
        wasteTypes: wasteTypes,
        vehicleType: vehicleType,
        distanceKm: distanceKm,
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
    String? photoPath,
    double? latitude,
    double? longitude,
    PaymentMethod paymentMethod = PaymentMethod.codTunai,
    double distanceKm = 0,
    List<WasteType>? wasteTypes,
    String? customerId,
    String? customerName,
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
        photoPath: photoPath,
        latitude: latitude,
        longitude: longitude,
        paymentMethod: paymentMethod,
        distanceKm: distanceKm,
        wasteTypes: wasteTypes,
        customerId: customerId,
        customerName: customerName,
      );
      emit(OrderCreated(order));
      AppNotificationStore.instance.add(
        title: order.syncStatus == 'pending'
            ? 'Pesanan Disimpan Offline'
            : 'Pesanan Diterima',
        message: order.syncStatus == 'pending'
            ? 'Pesanan ${order.id} disimpan dan akan disinkronkan saat koneksi kembali.'
            : 'Pesanan ${order.id} berhasil dibuat dan menunggu petugas.',
      );
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
      AppNotificationStore.instance.add(
        title: 'Pesanan Dibatalkan',
        message: 'Pesanan ${order.id} telah dibatalkan.',
      );
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
    } catch (e) {
      emit(OrderFailure('Gagal membatalkan pesanan: $e'));
    }
  }

  Future<void> takeOrder(
      {required String orderId, required String officerName}) async {
    emit(const OrderLoading());
    try {
      emit(OrderCreated(
          await assignOrder(orderId: orderId, officerName: officerName)));
      AppNotificationStore.instance.add(
        title: 'Petugas Menerima Pesanan',
        message: '$officerName menerima pesanan Anda dan sedang memprosesnya.',
      );
      AppNotificationStore.instance.add(
        title: 'Pesanan Diproses Petugas',
        message: 'Petugas mulai memproses pesanan $orderId.',
      );
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
      await loadOrders();
    }
  }

  Future<void> complete(String orderId) async {
    emit(const OrderLoading());
    try {
      final order = await completeOrder(orderId);
      emit(OrderCreated(order));
      AppNotificationStore.instance.add(
        title: 'Pesanan Selesai',
        message: 'Pesanan ${order.id} telah diselesaikan petugas.',
      );
    } on Failure catch (e) {
      emit(OrderFailure(e.message));
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
