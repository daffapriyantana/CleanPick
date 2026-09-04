import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/usecases/calculate_order_price.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import 'order_detail_page.dart';

class OrderDraft {
  final WasteType wasteType;
  final double weightKg;
  final String address;
  final DateTime pickupDate;
  final VehicleType vehicleType;
  final String? note;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final double distanceKm;

  const OrderDraft(
      {required this.wasteType,
      required this.weightKg,
      required this.address,
      required this.pickupDate,
      required this.vehicleType,
      this.note,
      this.photoPath,
      this.latitude,
      this.longitude,
      required this.distanceKm});
}

class OrderConfirmationPage extends StatefulWidget {
  final OrderDraft draft;
  const OrderConfirmationPage({super.key, required this.draft});

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  PaymentMethod _paymentMethod = PaymentMethod.codTunai;
  bool _submitting = false;

  String get _vaCode {
    final bank = switch (_paymentMethod) {
      PaymentMethod.vaBca => 'BCA',
      PaymentMethod.vaBni => 'BNI',
      PaymentMethod.vaBri => 'BRI',
      PaymentMethod.vaMandiri => 'MANDIRI',
      _ => '',
    };
    return bank.isEmpty ? '' : '8808 1200 2026 ${bank.hashCode.abs() % 10000}';
  }

  @override
  Widget build(BuildContext context) {
    final price = const CalculateOrderPrice().call(
      weightKg: widget.draft.weightKg,
      wasteType: widget.draft.wasteType,
      vehicleType: widget.draft.vehicleType,
      distanceKm: widget.draft.distanceKm,
    );
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => OrderDetailPage(orderId: state.order.id)));
          } else if (state is OrderFailure) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                  title: 'Lokasi Pengambilan',
                  value: widget.draft.address,
                  icon: Icons.location_on_outlined),
              _InfoCard(
                  title: 'Detail Sampah',
                  value:
                      '${widget.draft.wasteType.label} - ${widget.draft.weightKg} kg\n${widget.draft.vehicleType.label}',
                  icon: Icons.recycling_outlined),
              if (widget.draft.note != null)
                _InfoCard(
                    title: 'Catatan Petugas',
                    value: widget.draft.note!,
                    icon: Icons.notes_outlined),
              const SizedBox(height: 8),
              const Text('METODE PEMBAYARAN',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payments_outlined)),
                items: PaymentMethod.values
                    .map((method) => DropdownMenuItem(
                        value: method, child: Text(method.label)))
                    .toList(),
                onChanged: (method) => setState(() => _paymentMethod = method!),
              ),
              if (_paymentMethod.isCod)
                const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                        'Pembayaran dilakukan kepada petugas saat berada di lokasi.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)))
              else
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Kode Virtual Account: $_vaCode',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('RINCIAN BIAYA',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      _Row('Tarif Kendaraan', currency.format(price.baseFee)),
                      _Row(
                          'Biaya Jarak (${widget.draft.distanceKm.toStringAsFixed(1)} km)',
                          currency.format(price.distanceFee)),
                      _Row('Biaya Sampah', currency.format(price.weightFee)),
                      const Divider(),
                      _Row('Total', currency.format(price.total), bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _confirmOrder,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Pesan Sekarang'),
              ),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cek Kembali')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: const Text('Pastikan pesananmu sudah benar'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cek Kembali')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Iya')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    context.read<OrderCubit>().submitOrder(
          wasteType: widget.draft.wasteType,
          weightKg: widget.draft.weightKg,
          address: widget.draft.address,
          pickupDate: widget.draft.pickupDate,
          vehicleType: widget.draft.vehicleType,
          note: widget.draft.note,
          photoPath: widget.draft.photoPath,
          latitude: widget.draft.latitude,
          longitude: widget.draft.longitude,
          paymentMethod: _paymentMethod,
          distanceKm: widget.draft.distanceKm,
        );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _InfoCard(
      {required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          subtitle: Text(value,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textPrimary))));
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 12,
                color: bold ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.bold))
      ]));
}
