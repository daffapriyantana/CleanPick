import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';

/// Result of a price calculation, broken down so the UI can show a
/// rincian biaya (fee breakdown) exactly like the design mockups.
class OrderPriceResult {
  final double baseFee;
  final double weightFee;
  final double distanceFee;
  final double total;

  const OrderPriceResult({
    required this.baseFee,
    required this.weightFee,
    required this.distanceFee,
    required this.total,
  });
}

/// Pure business logic use case: no repository, no I/O. This is what
/// Test 1 & Test 2 (from the spec) exercise directly.
///
/// Rules:
/// - weight must be > 0, otherwise a [ValidationFailure] is thrown.
/// - total = (weight * ratePerKg) + vehicle base fee + distance fee.
class CalculateOrderPrice {
  const CalculateOrderPrice();

  OrderPriceResult call({
    required double weightKg,
    required WasteType wasteType,
    VehicleType vehicleType = VehicleType.motorRoda3,
    double distanceKm = 0,
  }) {
    if (weightKg <= 0) {
      throw const ValidationFailure('Berat sampah tidak boleh 0 atau negatif');
    }
    if (weightKg > vehicleType.maxCapacityKg) {
      throw ValidationFailure(
        'Berat melebihi kapasitas ${vehicleType.label} (${vehicleType.maxCapacityKg.toStringAsFixed(0)} kg)',
      );
    }

    final weightFee = weightKg * wasteType.ratePerKg;
    final distanceFee = distanceKm * kDistanceFeePerKm;
    final baseFee = vehicleType.baseFee;
    final total = baseFee + weightFee + distanceFee;

    return OrderPriceResult(
      baseFee: baseFee,
      weightFee: weightFee,
      distanceFee: distanceFee,
      total: total,
    );
  }
}
