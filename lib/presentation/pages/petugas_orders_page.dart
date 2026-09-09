import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import 'petugas_order_detail_page.dart';

class PetugasOrdersView extends StatefulWidget {
  final ValueChanged<String> onMessage;
  const PetugasOrdersView({super.key, required this.onMessage});

  @override
  State<PetugasOrdersView> createState() => _PetugasOrdersViewState();
}

class _PetugasOrdersViewState extends State<PetugasOrdersView> {
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderCubit>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _OrdersHeader(
        completed: _showCompleted,
        onChanged: (value) => setState(() => _showCompleted = value),
      ),
      Expanded(
        child: BlocConsumer<OrderCubit, OrderState>(
          listener: (context, state) {
            if (state is OrderFailure) widget.onMessage(state.message);
            if (state is OrderCreated) {
              widget.onMessage('Status pesanan diperbarui');
              context.read<OrderCubit>().loadOrders();
            }
          },
          builder: (context, state) {
            if (state is OrderInitial || state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrderFailure) {
              return Center(child: Text(state.message));
            }
            if (state is! OrdersLoaded) return const SizedBox.shrink();
            final auth = context.read<AuthCubit>().state;
            final officerId = auth is AuthSuccess ? auth.user.id : null;
            final orders = state.orders
                .where((order) => _showCompleted
                    ? order.status == OrderStatus.selesai &&
                        order.officerId == officerId
                    : order.status != OrderStatus.selesai &&
                        order.status != OrderStatus.dibatalkan)
                .toList()
              ..sort((a, b) {
                final aMine = a.officerId == officerId;
                final bMine = b.officerId == officerId;
                if (aMine != bMine) return aMine ? -1 : 1;
                return b.createdAt.compareTo(a.createdAt);
              });
            if (orders.isEmpty) {
              return Center(
                  child: Text(_showCompleted
                      ? 'Belum ada pesanan selesai'
                      : 'Tidak ada pesanan aktif'));
            }
            return RefreshIndicator(
              onRefresh: () => context.read<OrderCubit>().loadOrders(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                itemCount: orders.length,
                itemBuilder: (_, index) => _OrderCard(
                  order: orders[index],
                  onDetails: () => _openDetails(orders[index]),
                  onTake: orders[index].status == OrderStatus.menunggu
                      ? () => _take(orders[index])
                      : null,
                  onComplete: orders[index].status == OrderStatus.diproses
                      ? () =>
                          context.read<OrderCubit>().complete(orders[index].id)
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  void _take(OrderEntity order) {
    final auth = context.read<AuthCubit>().state;
    final name = auth is AuthSuccess ? auth.user.name : 'Petugas';
    context.read<OrderCubit>().takeOrder(orderId: order.id, officerName: name);
  }

  void _openDetails(OrderEntity order) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PetugasOrderDetailPage(
        orderId: order.id,
        customerName: order.customerName ?? 'Customer CleanPick',
        address: order.address,
        distance: '${order.distanceFee.toStringAsFixed(0)} km',
        wasteType: order.wasteType.label,
        vehicleType: order.vehicleType.label,
        vehicleFee: 'Rp ${order.baseFee.toStringAsFixed(0)}',
        distanceFee: 'Rp ${order.distanceFee.toStringAsFixed(0)}',
        total: 'Rp ${order.totalPrice.toStringAsFixed(0)}',
        photoPath: order.photoPath,
        latitude: order.latitude,
        longitude: order.longitude,
        paymentMethod: order.paymentMethod,
        onCompleted: () => context.read<OrderCubit>().complete(order.id),
        onCancelled: () => context.read<OrderCubit>().cancel(order.id),
      ),
    ));
  }
}

class _OrdersHeader extends StatelessWidget {
  final bool completed;
  final ValueChanged<bool> onChanged;
  const _OrdersHeader({required this.completed, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primaryDark,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pesanan',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _TabButton(
                    label: 'Aktif',
                    selected: !completed,
                    onPressed: () => onChanged(false))),
            const SizedBox(width: 12),
            Expanded(
                child: _TabButton(
                    label: 'Selesai',
                    selected: completed,
                    onPressed: () => onChanged(true))),
          ]),
        ]),
      );
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  const _TabButton(
      {required this.label, required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: selected ? AppColors.primary : Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(38),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onDetails;
  final VoidCallback? onTake;
  final VoidCallback? onComplete;
  const _OrderCard(
      {required this.order,
      required this.onDetails,
      this.onTake,
      this.onComplete});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(order.customerName ?? 'Customer CleanPick',
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              Text(order.status.label,
                  style: TextStyle(
                      color: order.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            Text(order.address,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text('${order.wasteType.label} • ${order.vehicleType.label}'),
            const SizedBox(height: 6),
            Text('Rp ${order.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.article_outlined, size: 17),
                      label: const Text('Detail Pesanan'))),
              if (onTake != null) ...[
                const SizedBox(width: 8),
                Expanded(
                    child: ElevatedButton(
                        onPressed: onTake, child: const Text('Ambil'))),
              ],
              if (onComplete != null) ...[
                const SizedBox(width: 8),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check, size: 17),
                        label: const Text('Selesai'))),
              ],
            ]),
          ]),
        ),
      );
}
