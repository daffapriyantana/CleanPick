import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/order_card.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  final bool embedded;
  const OrdersPage({super.key, this.embedded = false});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading || state is OrderInitial) {
          return const LoadingWidget(message: 'Memuat pesanan...');
        }
        if (state is OrderFailure) {
          return ErrorStateWidget(
            message: state.message,
            onRetry: () => context.read<OrderCubit>().loadOrders(),
          );
        }
        if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'Belum Ada Pesanan',
              subtitle: 'Pesanan yang Anda buat akan muncul di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<OrderCubit>().loadOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return OrderCard(
                  order: order,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );

    if (widget.embedded) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Pesanan Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Pesanan Saya')), body: body);
  }
}
