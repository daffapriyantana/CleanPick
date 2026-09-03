import 'package:flutter_test/flutter_test.dart';
import 'package:cleanpick/core/constants/app_constants.dart';
import 'package:cleanpick/core/error/failures.dart';
import 'package:cleanpick/domain/entities/order_entity.dart';
import 'package:cleanpick/domain/repositories/order_repository.dart';
import 'package:cleanpick/domain/usecases/create_order.dart';

/// A hand-written fake repository (no mocking framework needed) that
/// always "succeeds" so these tests isolate CreateOrder's own
/// validation logic -- exactly what Test 3 & Test 4 are about.
class _FakeOrderRepository implements OrderRepository {
  bool createOrderCalled = false;

  @override
  Future<OrderEntity> createOrder({
    required WasteType wasteType,
    required double weightKg,
    required String address,
    required DateTime pickupDate,
    required VehicleType vehicleType,
    String? note,
  }) async {
    createOrderCalled = true;
    return OrderEntity(
      id: 'CP-TEST-001',
      wasteType: wasteType,
      weightKg: weightKg,
      address: address,
      pickupDate: pickupDate,
      vehicleType: vehicleType,
      baseFee: vehicleType.baseFee,
      distanceFee: 0,
      weightFee: weightKg * wasteType.ratePerKg,
      totalPrice: vehicleType.baseFee + weightKg * wasteType.ratePerKg,
      status: OrderStatus.menunggu,
      paymentStatus: PaymentStatus.belumBayar,
      createdAt: DateTime.now(),
      note: note,
    );
  }

  @override
  Future<OrderEntity> cancelOrder(String orderId) => throw UnimplementedError();

  @override
  Future<OrderEntity> getOrderDetail(String orderId) => throw UnimplementedError();

  @override
  Future<List<OrderEntity>> getOrders() => throw UnimplementedError();

  @override
  Future<OrderEntity> payOrder(String orderId) => throw UnimplementedError();
}

void main() {
  late _FakeOrderRepository repository;
  late CreateOrder usecase;

  setUp(() {
    repository = _FakeOrderRepository();
    usecase = CreateOrder(repository);
  });

  group('CreateOrder', () {
    // ----- Test 3: Data pesanan valid -----
    test('Test 3 - pesanan dengan data lengkap berhasil dibuat', () async {
      final order = await usecase(
        wasteType: WasteType.organik,
        weightKg: 10,
        address: 'Jl. Contoh No. 10',
        pickupDate: DateTime.now().add(const Duration(days: 1)),
        vehicleType: VehicleType.motorRoda3,
      );

      expect(order, isA<OrderEntity>());
      expect(order.weightKg, 10);
      expect(repository.createOrderCalled, isTrue);
    });

    // ----- Test 4: Data pesanan tidak valid -----
    test('Test 4a - ditolak ketika jenis sampah tidak dipilih', () async {
      expect(
        () => usecase(
          wasteType: null,
          weightKg: 10,
          address: 'Jl. Contoh No. 10',
          pickupDate: DateTime.now(),
          vehicleType: VehicleType.motorRoda3,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.createOrderCalled, isFalse);
    });

    test('Test 4b - ditolak ketika berat 0/negatif', () async {
      expect(
        () => usecase(
          wasteType: WasteType.organik,
          weightKg: 0,
          address: 'Jl. Contoh No. 10',
          pickupDate: DateTime.now(),
          vehicleType: VehicleType.motorRoda3,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Test 4c - ditolak ketika alamat kosong', () async {
      expect(
        () => usecase(
          wasteType: WasteType.organik,
          weightKg: 10,
          address: '   ',
          pickupDate: DateTime.now(),
          vehicleType: VehicleType.motorRoda3,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Test 4d - ditolak ketika tanggal pengangkutan tidak dipilih', () async {
      expect(
        () => usecase(
          wasteType: WasteType.organik,
          weightKg: 10,
          address: 'Jl. Contoh No. 10',
          pickupDate: null,
          vehicleType: VehicleType.motorRoda3,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
