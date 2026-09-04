import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  PaymentMethod? _selectedPaymentMethod;
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pesanan berhasil dibatalkan')),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading) return const LoadingWidget();
          if (state is OrderFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<OrderCubit>().loadOrderDetail(widget.orderId),
            );
          }

          final order = state is OrderDetailLoaded
              ? state.order
              : state is OrderCancelled
                  ? state.order
                  : state is OrderPaid
                      ? state.order
                      : null;
          if (order == null) return const SizedBox.shrink();
          _selectedPaymentMethod ??= order.paymentMethod;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.id,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DETAIL PENGAMBILAN',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _infoRow('Alamat', order.address),
                        _infoRow('Jenis Sampah', order.wasteType.label),
                        _infoRow(
                            'Berat', '${order.weightKg.toStringAsFixed(1)} kg'),
                        _infoRow('Kendaraan', order.vehicleType.label),
                        _infoRow('Tanggal', dateFmt.format(order.pickupDate)),
                        if (order.officerName != null)
                          _infoRow('Petugas', order.officerName!),
                        if (order.note != null && order.note!.isNotEmpty)
                          _infoRow('Catatan', order.note!),
                        if (order.photoPath != null) ...[
                          const SizedBox(height: 8),
                          const Text('Foto untuk Petugas',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(order.photoPath!),
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                        ],
                        if (order.latitude != null &&
                            order.longitude != null) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openMap(order.latitude!, order.longitude!),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Lihat Titik Lokasi di Maps'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('METODE PEMBAYARAN',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<PaymentMethod>(
                          initialValue: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.payments_outlined)),
                          items: PaymentMethod.values
                              .map((method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(method.label),
                                  ))
                              .toList(),
                          onChanged: (method) =>
                              setState(() => _selectedPaymentMethod = method),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          (_selectedPaymentMethod ?? order.paymentMethod).isCod
                              ? 'Tunai atau QRIS ditunjukkan kepada petugas saat pickup.'
                              : 'Pembayaran dilakukan melalui Virtual Account bank pilihan.',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RINCIAN BIAYA',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _infoRow(
                            'Tarif Kendaraan', currency.format(order.baseFee)),
                        _infoRow(
                            'Biaya Sampah', currency.format(order.weightFee)),
                        _infoRow(
                            'Biaya Jarak', currency.format(order.distanceFee)),
                        const Divider(),
                        _infoRow(
                            'Total Biaya', currency.format(order.totalPrice),
                            bold: true),
                        _infoRow('Status Bayar', order.paymentStatus.label),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (order.status == OrderStatus.menunggu ||
                    order.status == OrderStatus.diproses)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(48)),
                    onPressed: () =>
                        context.read<OrderCubit>().cancel(order.id),
                    child: const Text('Batalkan Pesanan'),
                  ),
                if (order.paymentMethod.isCod)
                  _infoRow('Pembayaran COD', order.paymentMethod.label),
                if (!order.paymentMethod.isCod)
                  _infoRow('Kode Virtual Account', _virtualAccount(order)),
                if (order.paymentMethod.isCod &&
                    order.paymentStatus == PaymentStatus.belumBayar)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'Bayar kepada petugas saat tiba di lokasi. Petugas akan mengonfirmasi pembayaran.',
                        style: TextStyle(color: Colors.orange, fontSize: 11)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aplikasi Maps tidak tersedia')),
      );
    }
  }

  String _virtualAccount(OrderEntity order) {
    final bank = order.paymentMethod.label.replaceFirst('Virtual Account ', '');
    return '8808 1200 ${order.id.hashCode.abs() % 1000000} ($bank)';
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: bold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
