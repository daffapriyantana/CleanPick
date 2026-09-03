import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  const PaymentPage({super.key, required this.orderId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderPaid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pembayaran berhasil')),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading) return const LoadingWidget();
          if (state is OrderFailure) return ErrorStateWidget(message: state.message);

          final order = state is OrderDetailLoaded
              ? state.order
              : state is OrderPaid
                  ? state.order
                  : null;
          if (order == null) return const SizedBox.shrink();

          final isPaid = order.paymentStatus == PaymentStatus.lunas;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detail Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        _row('ID Pesanan', order.id),
                        _row('Tarif Kendaraan', currency.format(order.baseFee)),
                        _row('Biaya Sampah', currency.format(order.weightFee)),
                        _row('Biaya Jarak', currency.format(order.distanceFee)),
                        const Divider(height: 24),
                        _row('Total Pembayaran', currency.format(order.totalPrice), bold: true),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(isPaid ? Icons.check_circle : Icons.schedule, color: isPaid ? AppColors.primary : Colors.orange, size: 18),
                            const SizedBox(width: 6),
                            Text(order.paymentStatus.label, style: TextStyle(color: isPaid ? AppColors.primary : Colors.orange, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (!isPaid)
                  ElevatedButton(
                    onPressed: () => context.read<OrderCubit>().pay(order.id),
                    child: const Text('Bayar Sekarang'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: bold ? AppColors.primary : AppColors.textPrimary, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
