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
import 'petugas_order_detail_page.dart';
import 'petugas_orders_page.dart';

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
    final name = user?.name ?? 'Ahmad';
    final id = user?.id ?? 'PTG-001';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: _selectedIndex == 1
            ? PetugasOrdersView(onMessage: _showMessage)
            : _selectedIndex == 2
                ? const PetugasIncomeView()
                : Column(
                    children: [
                      _Header(name: name, id: id),
                      Expanded(
                        child: _LivePetugasHome(
                          officerName: name,
                          onMessage: _showMessage,
                        ),
                        /* SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle('Ringkasan Hari Ini'),
                              const SizedBox(height: 10),
                              const Row(
                                children: [
                                  Expanded(
                                      child: _StatisticCard(
                                          label: 'Hari Ini',
                                          value: '5',
                                          caption: 'Pesanan')),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: _StatisticCard(
                                          label: 'Selesai',
                                          value: '3',
                                          caption: 'Penjemputan')),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: _StatisticCard(
                                          label: 'Pendapatan',
                                          value: 'Rp 175rb',
                                          caption: 'Dari Petugas')),
                                ],
                              ),
                              const SizedBox(height: 22),
                              const _SectionTitle('Pesanan Aktif'),
                              const SizedBox(height: 10),
                              if (_activeCustomer != null)
                                _ActivePickupCard(
                                  customerName: _activeCustomer!,
                                  address: _activeCustomer == 'Siti Rahma'
                                      ? 'Jl. Kenanga Indah No. 45, Kebayoran Baru'
                                      : _activeCustomer == 'Budi Santoso'
                                          ? 'Jl. Pondok Indah Mall, Area Pickup Utara'
                                          : 'Jl. Melati Indah No. 12, Cilandak',
                                  onDetail: () => _openOrderDetail(
                                    customerName: _activeCustomer!,
                                    address: _activeCustomer == 'Siti Rahma'
                                        ? 'Jl. Kenanga Indah No. 45, Kebayoran Baru'
                                        : _activeCustomer == 'Budi Santoso'
                                            ? 'Jl. Pondok Indah Mall, Area Pickup Utara'
                                            : 'Jl. Melati Indah No. 12, Cilandak',
                                    distance: '2.3 km',
                                    wasteType: 'Plastik',
                                    vehicleType: 'Pickup Box',
                                    vehicleFee: 'Rp 35.000',
                                    distanceFee: 'Rp 10.000',
                                    total: 'Rp 45.000',
                                  ),
                                ),
                              const SizedBox(height: 22),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _SectionTitle('Pesanan Masuk'),
                                  _Pill(
                                      label: '2 Baru',
                                      background: Color(0xFFFEE2E2),
                                      foreground: AppColors.error),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _IncomingOrderCard(
                                name: 'Budi Santoso',
                                time: '5 menit yang lalu',
                                distance: '2.3 km',
                                address:
                                    'Jl. Pondok Indah Mall, Area Pickup Utara',
                                chips: const [
                                  (
                                    'Plastik',
                                    Color(0xFFDBEAFE),
                                    Color(0xFF2563EB)
                                  ),
                                  (
                                    'Kertas',
                                    Color(0xFFFEF3C7),
                                    Color(0xFFD97706)
                                  ),
                                  (
                                    'Pickup',
                                    Color(0xFFDCFCE7),
                                    Color(0xFF15803D)
                                  )
                                ],
                                price: 'Rp 45.000',
                                accepted: _acceptedCustomer == 'Budi Santoso',
                                onAccept: () => _acceptOrder('Budi Santoso'),
                                onReject: () => _showMessage(
                                    'Pesanan Budi Santoso ditolak'),
                                onDetail: () => _openOrderDetail(
                                  customerName: 'Budi Santoso',
                                  address:
                                      'Jl. Pondok Indah Mall, Area Pickup Utara',
                                  distance: '2.3 km',
                                  wasteType: 'Plastik',
                                  vehicleType: 'Pickup Box',
                                  vehicleFee: 'Rp 35.000',
                                  distanceFee: 'Rp 10.000',
                                  total: 'Rp 45.000',
                                ),
                              ),
                              const SizedBox(height: 10),
                              _IncomingOrderCard(
                                name: 'Dewi Lestari',
                                time: '10 menit yang lalu',
                                distance: '4.1 km',
                                address: 'Jl. Melati Indah No. 12, Cilandak',
                                chips: const [
                                  (
                                    'Organik',
                                    Color(0xFFDCFCE7),
                                    Color(0xFF15803D)
                                  ),
                                  (
                                    'Motor Tiga',
                                    Color(0xFFF3E8FF),
                                    Color(0xFF7E22CE)
                                  )
                                ],
                                price: 'Rp 30.000',
                                accepted: _acceptedCustomer == 'Dewi Lestari',
                                onAccept: () => _acceptOrder('Dewi Lestari'),
                                onReject: () => _showMessage(
                                    'Pesanan Dewi Lestari ditolak'),
                                onDetail: () => _openOrderDetail(
                                  customerName: 'Dewi Lestari',
                                  address: 'Jl. Melati Indah No. 12, Cilandak',
                                  distance: '4.1 km',
                                  wasteType: 'Organik',
                                  vehicleType: 'Motor Tiga',
                                  vehicleFee: 'Rp 25.000',
                                  distanceFee: 'Rp 5.000',
                                  total: 'Rp 30.000',
                                ),
                              ),
                            ],
                          ),
                        ), */
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 3) {
            _showMessage('Menu ini segera tersedia');
          }
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LivePetugasHome extends StatelessWidget {
  final String officerName;
  final ValueChanged<String> onMessage;

  const _LivePetugasHome({required this.officerName, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderFailure) onMessage(state.message);
        if (state is OrderCreated &&
            state.order.status == OrderStatus.diproses) {
          onMessage('Pesanan ${state.order.id} berhasil diambil');
          context.read<OrderCubit>().loadOrders();
        }
        if (state is OrderCreated &&
            state.order.status == OrderStatus.selesai) {
          onMessage('Pesanan ${state.order.id} selesai');
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

        final active = state.orders
            .where((order) =>
                order.status == OrderStatus.diproses &&
                order.officerName == officerName)
            .toList();
        final incoming = state.orders
            .where((order) => order.status == OrderStatus.menunggu)
            .toList();

        return RefreshIndicator(
          onRefresh: () => context.read<OrderCubit>().loadOrders(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _SectionTitle('Pesanan Aktif'),
              const SizedBox(height: 10),
              if (active.isEmpty)
                const _EmptyLiveOrder(message: 'Belum ada pesanan aktif')
              else
                ...active.map((order) => _LiveOrderCard(
                      order: order,
                      active: true,
                      onDetails: () => _openOrderDetail(context, order),
                      onComplete: () =>
                          context.read<OrderCubit>().complete(order.id),
                    )),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle('Pesanan Masuk'),
                  _Pill(
                    label: '${incoming.length} Baru',
                    background: const Color(0xFFFEE2E2),
                    foreground: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (incoming.isEmpty)
                const _EmptyLiveOrder(message: 'Belum ada pesanan customer')
              else
                ...incoming.map((order) => _LiveOrderCard(
                      order: order,
                      active: false,
                      onDetails: () => _openOrderDetail(context, order),
                      onTake: () => context.read<OrderCubit>().takeOrder(
                            orderId: order.id,
                            officerName: officerName,
                          ),
                    )),
            ],
          ),
        );
      },
    );
  }

  void _openOrderDetail(BuildContext context, OrderEntity order) {
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

class _LiveOrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool active;
  final VoidCallback? onTake;
  final VoidCallback? onDetails;
  final VoidCallback? onComplete;

  const _LiveOrderCard({
    required this.order,
    required this.active,
    this.onTake,
    this.onDetails,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border:
            Border.all(color: active ? AppColors.primary : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              order.customerName ?? 'Customer CleanPick',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          _Pill(
            label: active ? 'Diproses' : 'Menunggu',
            background:
                active ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
            foreground:
                active ? const Color(0xFF2563EB) : const Color(0xFFD97706),
          ),
        ]),
        const SizedBox(height: 9),
        Text(order.address,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(
            '${order.wasteType.label} • ${order.vehicleType.label} • Rp ${order.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDetails,
                icon: const Icon(Icons.article_outlined, size: 17),
                label: const Text('Detail Pesanan'),
              ),
            ),
            if (!active) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTake,
                  icon:
                      const Icon(Icons.assignment_turned_in_outlined, size: 17),
                  label: const Text('Ambil'),
                ),
              ),
            ] else ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text('Selesai'),
                ),
              ),
            ],
          ],
        ),
      ]),
    );
  }
}

class _EmptyLiveOrder extends StatelessWidget {
  final String message;
  const _EmptyLiveOrder({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Text(message,
                style: const TextStyle(color: AppColors.textSecondary))),
      );
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
                    const _Pill(
                        label: '● ONLINE',
                        background: Color(0xFFDCFCE7),
                        foreground: Color(0xFF15803D)),
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
