import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import 'dart:math' as math;

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

  double distanceFromDepot(
      {required double latitude, required double longitude}) {
    const earthRadiusKm = 6371.0;
    final lat1 = latitude * math.pi / 180;
    const lat2 = kCleanPickDepotLatitude * math.pi / 180;
    final deltaLat = (kCleanPickDepotLatitude - latitude) * math.pi / 180;
    final deltaLon = (kCleanPickDepotLongitude - longitude) * math.pi / 180;
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  OrderPriceResult call({
    required double weightKg,
    required WasteType wasteType,
    List<WasteType>? wasteTypes,
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

    final types =
        wasteTypes == null || wasteTypes.isEmpty ? [wasteType] : wasteTypes;
    final averageRate =
        types.fold<double>(0, (sum, type) => sum + type.ratePerKg) /
            types.length;
    final b3Surcharge = types.contains(WasteType.b3) ? 0.25 : 0;
    final weightFee = weightKg * averageRate * (1 + b3Surcharge);
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
