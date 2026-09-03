import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/order_card.dart';
import 'order_detail_page.dart';

class HistoryPage extends StatefulWidget {
  final bool embedded;
  const HistoryPage({super.key, this.embedded = false});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading || state is OrderInitial) return const LoadingWidget();
        if (state is OrderFailure) {
          return ErrorStateWidget(message: state.message, onRetry: () => context.read<OrderCubit>().loadOrders());
        }
        if (state is OrdersLoaded) {
          final finished = state.orders.where((o) => o.status == OrderStatus.selesai).toList();
          if (finished.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history,
              title: 'Belum Ada Riwayat',
              subtitle: 'Pesanan yang sudah selesai akan tampil di sini.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: finished.length,
            itemBuilder: (context, i) => OrderCard(
              order: finished[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: finished[i].id)),
              ),
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
              child: Text('Riwayat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Riwayat')), body: body);
  }
}
