import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import 'petugas_income_page.dart';
import 'petugas_orders_page.dart';
import '../widgets/connectivity_banner.dart';
import 'petugas_profile_page.dart';

class PetugasDashboardPage extends StatefulWidget {
  const PetugasDashboardPage({super.key});

  @override
  State<PetugasDashboardPage> createState() => _PetugasDashboardPageState();
}

class _PetugasDashboardPageState extends State<PetugasDashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderCubit>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;
    final name = user?.name ?? 'Petugas';
    final id = user?.id ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: BlocListener<OrderCubit, OrderState>(
                listener: (context, state) {
                  if (_selectedIndex == 0 && state is OrderFailure) {
                    _showMessage(state.message);
                  }
                },
                child: _selectedIndex == 1
                    ? PetugasOrdersView(onMessage: _showMessage)
                    : _selectedIndex == 2
                        ? const PetugasIncomeView()
                        : _selectedIndex == 3
                            ? const PetugasProfilePage()
                            : Column(children: [
                                _Header(name: name, id: id),
                                Expanded(
                                    child: _OfficerHomeContent(
                                        officerId: user?.id)),
                              ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OfficerHomeContent extends StatelessWidget {
  final String? officerId;
  const _OfficerHomeContent({required this.officerId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading || state is OrderInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = state is OrdersLoaded ? state.orders : <OrderEntity>[];
        final active = orders
            .where((order) =>
                order.officerId == officerId &&
                order.status != OrderStatus.selesai &&
                order.status != OrderStatus.dibatalkan)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final incoming = orders
            .where((order) => order.status == OrderStatus.menunggu)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final hasActiveTask = active.isNotEmpty;
        final completed = orders.where((order) =>
            order.officerId == officerId &&
            order.status == OrderStatus.selesai);
        final income = completed.fold<double>(
            0, (total, order) => total + order.totalPrice);

        return RefreshIndicator(
          onRefresh: () => context.read<OrderCubit>().loadOrders(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _SectionTitle('Ringkasan Hari Ini'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _StatisticCard(
                        label: 'Aktif',
                        value: '${active.length}',
                        caption: 'Pesanan')),
                const SizedBox(width: 8),
                Expanded(
                    child: _StatisticCard(
                        label: 'Selesai',
                        value: '${completed.length}',
                        caption: 'Penjemputan')),
                const SizedBox(width: 8),
                Expanded(
                    child: _StatisticCard(
                        label: 'Pendapatan',
                        value: 'Rp ${income.toStringAsFixed(0)}',
                        caption: 'Selesai')),
              ]),
              const SizedBox(height: 22),
              const _SectionTitle('Pesanan Aktif'),
              const SizedBox(height: 10),
              if (active.isEmpty)
                const _OfficerEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Belum ada pesanan aktif',
                    message: 'Pesanan yang Anda ambil akan tampil di sini.')
              else
                ...active.map((order) => _DynamicOrderTile(order: order)),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle('Pesanan Masuk'),
                  _Pill(
                      label: '${incoming.length} Baru',
                      background: const Color(0xFFFEE2E2),
                      foreground: AppColors.error),
                ],
              ),
              const SizedBox(height: 10),
              if (incoming.isEmpty)
                const _OfficerEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Belum ada pesanan masuk',
                    message: 'Pesanan dari customer akan muncul di sini.')
              else
                ...incoming.map((order) => _DynamicOrderTile(
                      order: order,
                      canTake: !hasActiveTask,
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _OfficerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _OfficerEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 38, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
}

class _DynamicOrderTile extends StatelessWidget {
  final OrderEntity order;
  final bool canTake;
  const _DynamicOrderTile({required this.order, this.canTake = true});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final officerName = auth is AuthSuccess ? auth.user.name : 'Petugas';
    final canTakeOrder = order.status == OrderStatus.menunggu && canTake;
    final canComplete = order.status == OrderStatus.diproses;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(order.customerName ?? 'Customer CleanPick',
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Text(order.status.label,
                style: TextStyle(
                    color: order.status.color, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 7),
          Text(order.address,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text('${order.wasteType.label} • ${order.vehicleType.label}'),
          const SizedBox(height: 6),
          Text('Rp ${order.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            if (order.status == OrderStatus.menunggu)
              Expanded(
                  child: ElevatedButton(
                  onPressed: canTakeOrder
                    ? () => context.read<OrderCubit>().takeOrder(
                      orderId: order.id, officerName: officerName)
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Selesaikan tugas aktif sebelum mengambil order lain.'))),
                      child: const Text('Ambil Pesanan'))),
            if (canComplete)
              Expanded(
                  child: ElevatedButton(
                      onPressed: () =>
                          context.read<OrderCubit>().complete(order.id),
                      child: const Text('Tandai Selesai'))),
          ]),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String id;
  const _Header({required this.name, required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFDCFCE7),
            child: Icon(Icons.person, color: AppColors.primary, size: 27),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, $name!',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('ID: $id',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    const ConnectionStatusIndicator(
                        foregroundColor: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            style:
                IconButton.styleFrom(backgroundColor: const Color(0xFFECFDF5)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi baru'))),
            icon: const Icon(Icons.notifications_none,
                color: AppColors.primary, size: 21),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  const _StatisticCard(
      {required this.label, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 8, 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary))),
        const SizedBox(height: 3),
        Text(caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary));
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  const _Pill(
      {required this.label,
      required this.background,
      required this.foreground});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: foreground, fontSize: 9, fontWeight: FontWeight.w700)),
      );
}

// ignore: unused_element
class _ActivePickupCard extends StatelessWidget {
  final String customerName;
  final String address;
  final VoidCallback onDetail;
  const _ActivePickupCard({
    required this.customerName,
    required this.address,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.primary, width: 1.3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(customerName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold))),
          const _Pill(
              label: 'Menuju Lokasi',
              background: Color(0xFFDCFCE7),
              foreground: Color(0xFF15803D)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.location_on_outlined,
              color: AppColors.primary, size: 17),
          const SizedBox(width: 6),
          Expanded(
              child: Text(address,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary))),
        ]),
        const SizedBox(height: 11),
        Row(children: [
          const Text('Estimasi Tarif: ',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const Text('Rp 45.000',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(
              onPressed: onDetail,
              child: const Text('Lihat Detail',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        ]),
      ]),
    );
  }
}

// ignore: unused_element
class _IncomingOrderCard extends StatelessWidget {
  final String name;
  final String time;
  final String distance;
  final String address;
  final List<(String, Color, Color)> chips;
  final String price;
  final bool accepted;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDetail;
  const _IncomingOrderCard(
      {required this.name,
      required this.time,
      required this.distance,
      required this.address,
      required this.chips,
      required this.price,
      required this.accepted,
      required this.onAccept,
      required this.onReject,
      required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold))),
          Text(time,
              style:
                  const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 5),
        Row(children: [
          const Icon(Icons.near_me_outlined,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(distance,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 7),
        Text(address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 5,
            runSpacing: 4,
            children: chips
                .map((chip) => _Pill(
                    label: chip.$1, background: chip.$2, foreground: chip.$3))
                .toList()),
        const Divider(height: 20),
        Row(children: [
          Text(price,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark)),
          const Spacer(),
          if (accepted)
            ElevatedButton.icon(
              onPressed: onDetail,
              icon: const Icon(Icons.receipt_long_outlined, size: 15),
              label:
                  const Text('Detail Pesanan', style: TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(124, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7))),
            )
          else ...[
            OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(68, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10)),
                child: const Text('Tolak', style: TextStyle(fontSize: 10))),
            const SizedBox(width: 7),
            ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(72, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7))),
                child: const Text('Terima', style: TextStyle(fontSize: 10))),
          ],
        ]),
      ]),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _BottomNavigation(
      {required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border))),
        child: NavigationBar(
          height: 66,
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDCFCE7),
          labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.primary),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
                label: 'Pesanan'),
            NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments, color: AppColors.primary),
                label: 'Pendapatan'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.primary),
                label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
