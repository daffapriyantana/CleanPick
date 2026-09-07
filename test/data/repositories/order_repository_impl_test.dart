import 'package:flutter_test/flutter_test.dart';
import 'package:cleanpick/core/constants/app_constants.dart';
import 'package:cleanpick/core/error/exceptions.dart';
import 'package:cleanpick/core/error/failures.dart';
import 'package:cleanpick/data/datasources/order_local_datasource.dart';
import 'package:cleanpick/data/models/order_model.dart';
import 'package:cleanpick/data/repositories/order_repository_impl.dart';

/// Fake datasource so this test exercises only the repository's
/// translation of exceptions -> failures, independent of the real
/// in-memory implementation.
class _FakeDataSource implements OrderLocalDataSource {
  bool shouldThrow = false;
  final List<OrderModel> orders;
  _FakeDataSource(this.orders);

  @override
  Future<OrderModel> cancelOrder(String orderId) async {
    if (shouldThrow) throw const ServerException('not found');
    return orders.first;
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async => order;

  @override
  Future<OrderModel> assignOrder(
          {required String orderId, required String officerName}) async =>
      orders.first;

  @override
  Future<OrderModel> getOrderDetail(String orderId) async {
    if (shouldThrow) throw const ServerException('Pesanan tidak ditemukan');
    return orders.first;
  }

  @override
  Future<List<OrderModel>> getOrders() async => orders;

  @override
  Future<OrderModel> payOrder(String orderId) async => orders.first;
  @override
  Future<OrderModel> completeOrder(String orderId) async => orders.first;
}

void main() {
  late _FakeDataSource dataSource;
  late OrderRepositoryImpl repository;

  final sampleOrder = OrderModel(
    id: 'CP-001',
    wasteType: WasteType.organik,
    weightKg: 10,
    address: 'Jl. Contoh No. 10',
    pickupDate: DateTime.now(),
    vehicleType: VehicleType.motorRoda3,
    baseFee: 25000,
    distanceFee: 0,
    weightFee: 20000,
    totalPrice: 45000,
    status: OrderStatus.menunggu,
    paymentStatus: PaymentStatus.belumBayar,
    createdAt: DateTime.now(),
  );

  setUp(() {
    dataSource = _FakeDataSource([sampleOrder]);
    repository = OrderRepositoryImpl(dataSource: dataSource);
  });

  test('getOrders mengembalikan daftar pesanan dari datasource', () async {
    final result = await repository.getOrders();
    expect(result, hasLength(1));
    expect(result.first.id, 'CP-001');
  });

  test(
      'getOrderDetail melempar ServerFailure ketika datasource melempar ServerException',
      () async {
    dataSource.shouldThrow = true;
    expect(() => repository.getOrderDetail('unknown'),
        throwsA(isA<ServerFailure>()));
  });

  test('createOrder menghitung harga lalu meneruskan ke datasource', () async {
    final result = await repository.createOrder(
      wasteType: WasteType.organik,
      weightKg: 10,
      address: 'Jl. Contoh No. 10',
      pickupDate: DateTime.now(),
      vehicleType: VehicleType.motorRoda3,
    );
    expect(result.totalPrice, greaterThan(0));
    expect(result.weightFee, 10 * WasteType.organik.ratePerKg);
  });
}
