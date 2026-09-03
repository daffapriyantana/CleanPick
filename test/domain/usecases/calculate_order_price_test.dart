import 'package:flutter_test/flutter_test.dart';
import 'package:cleanpick/core/constants/app_constants.dart';
import 'package:cleanpick/core/error/failures.dart';
import 'package:cleanpick/domain/usecases/calculate_order_price.dart';

void main() {
  late CalculateOrderPrice usecase;

  setUp(() {
    usecase = const CalculateOrderPrice();
  });

  group('CalculateOrderPrice', () {
    // ----- Test 1: Perhitungan tarif berhasil -----
    test('Test 1 - menghitung total tarif dengan benar (10kg organik @Rp2.000)', () {
      final result = usecase(
        weightKg: 10,
        wasteType: WasteType.organik,
        vehicleType: VehicleType.motorRoda3,
        distanceKm: 0,
      );

      // weightFee = 10 * 2000 = 20.000, sesuai contoh pada spesifikasi.
      expect(result.weightFee, 20000);
      // total juga menyertakan baseFee kendaraan (tidak ada di contoh
      // sederhana spek, tapi wajib konsisten dengan implementasi nyata).
      expect(result.total, result.baseFee + result.weightFee + result.distanceFee);
      expect(result.total, greaterThanOrEqualTo(20000));
    });

    // ----- Test 2: Berat tidak valid -----
    test('Test 2 - melempar ValidationFailure ketika berat 0', () {
      expect(
        () => usecase(weightKg: 0, wasteType: WasteType.organik),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('Test 2b - melempar ValidationFailure ketika berat negatif', () {
      expect(
        () => usecase(weightKg: -5, wasteType: WasteType.organik),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('melempar ValidationFailure ketika berat melebihi kapasitas kendaraan', () {
      expect(
        () => usecase(
          weightKg: 500,
          wasteType: WasteType.organik,
          vehicleType: VehicleType.motorRoda3, // max 100kg
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
