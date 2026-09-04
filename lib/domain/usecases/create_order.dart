import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

/// Validates the incoming order request before delegating to the
/// repository. Keeping validation here (not in the UI, not in the
/// datasource) is what Test 3 & Test 4 exercise.
class CreateOrder {
  final OrderRepository repository;

  const CreateOrder(this.repository);

  Future<OrderEntity> call({
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
  }) async {
    if (wasteType == null) {
      throw const ValidationFailure('Jenis sampah wajib dipilih');
    }
    if (weightKg <= 0) {
      throw const ValidationFailure('Berat sampah tidak boleh 0 atau negatif');
    }
    if (address.trim().isEmpty) {
      throw const ValidationFailure('Alamat wajib diisi');
    }
    if (pickupDate == null) {
      throw const ValidationFailure('Tanggal pengangkutan wajib dipilih');
    }

    return repository.createOrderWithDetails(
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
    );
  }
}
