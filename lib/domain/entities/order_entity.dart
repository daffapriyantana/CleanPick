import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class OrderEntity extends Equatable {
  final String id;
  final WasteType wasteType;
  final double weightKg;
  final String address;
  final DateTime pickupDate;
  final VehicleType vehicleType;
  final double baseFee;
  final double distanceFee;
  final double weightFee;
  final double totalPrice;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final String? note;
  final String? officerName;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final PaymentMethod paymentMethod;
  final List<WasteType> wasteTypes;
  final String? customerId;
  final String? customerName;
  final String? officerId;
  final int? officerRating;
  final String? complaint;

  const OrderEntity({
    required this.id,
    required this.wasteType,
    required this.weightKg,
    required this.address,
    required this.pickupDate,
    required this.vehicleType,
    required this.baseFee,
    required this.distanceFee,
    required this.weightFee,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.note,
    this.officerName,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.paymentMethod = PaymentMethod.codTunai,
    this.wasteTypes = const [],
    this.customerId,
    this.customerName,
    this.officerId,
    this.officerRating,
    this.complaint,
  });

  List<WasteType> get selectedWasteTypes =>
      wasteTypes.isEmpty ? [wasteType] : List.unmodifiable(wasteTypes);

  OrderEntity copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? customerId,
    String? customerName,
    String? officerId,
    String? officerName,
    String? photoPath,
    double? latitude,
    double? longitude,
    PaymentMethod? paymentMethod,
    List<WasteType>? wasteTypes,
    int? officerRating,
    String? complaint,
  }) {
    return OrderEntity(
      id: id,
      wasteType: wasteType,
      weightKg: weightKg,
      address: address,
      pickupDate: pickupDate,
      vehicleType: vehicleType,
      baseFee: baseFee,
      distanceFee: distanceFee,
      weightFee: weightFee,
      totalPrice: totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
      note: note,
      officerName: officerName ?? this.officerName,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      wasteTypes: wasteTypes ?? this.wasteTypes,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      officerId: officerId ?? this.officerId,
      officerRating: officerRating ?? this.officerRating,
      complaint: complaint ?? this.complaint,
    );
  }

  @override
  List<Object?> get props => [
        id,
        wasteType,
        weightKg,
        address,
        pickupDate,
        vehicleType,
        baseFee,
        distanceFee,
        weightFee,
        totalPrice,
        status,
        paymentStatus,
        createdAt,
        note,
        officerName,
        photoPath,
        latitude,
        longitude,
        paymentMethod,
        wasteTypes,
        customerId,
        customerName,
        officerId,
        officerRating,
        complaint,
      ];
}
