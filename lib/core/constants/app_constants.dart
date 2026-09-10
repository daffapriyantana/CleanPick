import 'package:flutter/material.dart';

/// Waste types offered by CleanPick, each with its own rate per kg.
enum WasteType { organik, anorganik, b3, daurUlang }

extension WasteTypeX on WasteType {
  String get label {
    switch (this) {
      case WasteType.organik:
        return 'Organik';
      case WasteType.anorganik:
        return 'Anorganik';
      case WasteType.b3:
        return 'B3 (Bahaya)';
      case WasteType.daurUlang:
        return 'Daur Ulang';
    }
  }

  /// Rate in Rupiah per kilogram. B3 (hazardous) waste costs more to
  /// process safely; recyclables are cheaper to encourage sorting.
  double get ratePerKg {
    switch (this) {
      case WasteType.organik:
        return 2000;
      case WasteType.anorganik:
        return 2500;
      case WasteType.b3:
        return 5000;
      case WasteType.daurUlang:
        return 1500;
    }
  }
}

/// Vehicle options shown on the "Buat Pesanan" page, each with a
/// flat distance/vehicle fee and a maximum capacity in kg.
enum VehicleType { motorRoda3, pickup, truk }

extension VehicleTypeX on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.motorRoda3:
        return 'Motor Roda Tiga';
      case VehicleType.pickup:
        return 'Pickup';
      case VehicleType.truk:
        return 'Truk';
    }
  }

  double get maxCapacityKg {
    switch (this) {
      case VehicleType.motorRoda3:
        return 100;
      case VehicleType.pickup:
        return 500;
      case VehicleType.truk:
        return 1000000; // effectively no limit for this demo
    }
  }

  double get baseFee {
    switch (this) {
      case VehicleType.motorRoda3:
        return 25000;
      case VehicleType.pickup:
        return 35000;
      case VehicleType.truk:
        return 60000;
    }
  }
}

/// Flat fee charged per km of distance between customer & depot.
/// Kept as a constant here so both the domain use case and any UI
/// preview use exactly the same number.
const double kDistanceFeePerKm = 3000;
const double kCleanPickDepotLatitude = -6.2088;
const double kCleanPickDepotLongitude = 106.8456;

/// Order lifecycle status, in the order the docs describe.
enum OrderStatus { menunggu, diproses, dijadwalkan, selesai, dibatalkan }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.menunggu:
        return 'Menunggu';
      case OrderStatus.diproses:
        return 'Diproses';
      case OrderStatus.dijadwalkan:
        return 'Dijadwalkan';
      case OrderStatus.selesai:
        return 'Selesai';
      case OrderStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.menunggu:
        return const Color(0xFFF5A524);
      case OrderStatus.diproses:
        return const Color(0xFF3B82F6);
      case OrderStatus.dijadwalkan:
        return const Color(0xFF8B5CF6);
      case OrderStatus.selesai:
        return const Color(0xFF16A34A);
      case OrderStatus.dibatalkan:
        return const Color(0xFFDC2626);
    }
  }
}

enum PaymentStatus { belumBayar, lunas }

extension PaymentStatusX on PaymentStatus {
  String get label => this == PaymentStatus.lunas ? 'Lunas' : 'Belum Bayar';
}

enum PaymentMethod { codTunai, codQris, vaBca, vaBni, vaBri, vaMandiri }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.codTunai:
        return 'COD - Tunai';
      case PaymentMethod.codQris:
        return 'QRIS';
      case PaymentMethod.vaBca:
        return 'Virtual Account BCA';
      case PaymentMethod.vaBni:
        return 'Virtual Account BNI';
      case PaymentMethod.vaBri:
        return 'Virtual Account BRI';
      case PaymentMethod.vaMandiri:
        return 'Virtual Account Mandiri';
    }
  }

  bool get isCod => this == PaymentMethod.codTunai;

  bool get requiresOnlinePayment => this != PaymentMethod.codTunai;
}
