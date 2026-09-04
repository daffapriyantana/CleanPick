import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import 'petugas_order_detail_page.dart';
import 'petugas_orders_page.dart';

class PetugasDashboardPage extends StatefulWidget {
  const PetugasDashboardPage({super.key});

  @override
  State<PetugasDashboardPage> createState() => _PetugasDashboardPageState();
}

class _PetugasDashboardPageState extends State<PetugasDashboardPage> {
  int _selectedIndex = 0;
  String? _activeCustomer = 'Siti Rahma';
  String? _acceptedCustomer;

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
            : Column(
          children: [
            _Header(name: name, id: id),
            Expanded(
              child: SingleChildScrollView(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      address: 'Jl. Pondok Indah Mall, Area Pickup Utara',
                      chips: const [
                        ('Plastik', Color(0xFFDBEAFE), Color(0xFF2563EB)),
                        ('Kertas', Color(0xFFFEF3C7), Color(0xFFD97706)),
                        ('Pickup', Color(0xFFDCFCE7), Color(0xFF15803D))
                      ],
                      price: 'Rp 45.000',
                      accepted: _acceptedCustomer == 'Budi Santoso',
                      onAccept: () => _acceptOrder('Budi Santoso'),
                      onReject: () =>
                          _showMessage('Pesanan Budi Santoso ditolak'),
                      onDetail: () => _openOrderDetail(
                        customerName: 'Budi Santoso',
                        address: 'Jl. Pondok Indah Mall, Area Pickup Utara',
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
                        ('Organik', Color(0xFFDCFCE7), Color(0xFF15803D)),
                        ('Motor Tiga', Color(0xFFF3E8FF), Color(0xFF7E22CE))
                      ],
                      price: 'Rp 30.000',
                      accepted: _acceptedCustomer == 'Dewi Lestari',
                      onAccept: () => _acceptOrder('Dewi Lestari'),
                      onReject: () =>
                          _showMessage('Pesanan Dewi Lestari ditolak'),
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index != 0 && index != 1) {
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

  void _acceptOrder(String customerName) {
    if (_activeCustomer != null) {
      _showActiveOrderDialog();
      return;
    }
    setState(() {
      _acceptedCustomer = customerName;
      _activeCustomer = customerName;
    });
    _showMessage('Pesanan $customerName diterima');
  }

  Future<void> _showActiveOrderDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pesanan Aktif'),
        content: const Text(
            'Selesaikan atau batalkan pesanan aktif terlebih dahulu sebelum menerima pesanan lain.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _completeActiveOrder() {
    final customerName = _activeCustomer;
    setState(() {
      _activeCustomer = null;
      _acceptedCustomer = null;
    });
    _showMessage(
        'Pesanan ${customerName ?? ''} selesai. Anda bisa menerima pesanan baru');
  }

  void _cancelActiveOrder() {
    final customerName = _activeCustomer;
    setState(() {
      _activeCustomer = null;
      _acceptedCustomer = null;
    });
    _showMessage(
        'Pesanan ${customerName ?? ''} dibatalkan. Anda bisa menerima pesanan baru');
  }

  void _openOrderDetail({
    required String customerName,
    required String address,
    required String distance,
    required String wasteType,
    required String vehicleType,
    required String vehicleFee,
    required String distanceFee,
    required String total,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetugasOrderDetailPage(
          customerName: customerName,
          address: address,
          distance: distance,
          wasteType: wasteType,
          vehicleType: vehicleType,
          vehicleFee: vehicleFee,
          distanceFee: distanceFee,
          total: total,
          onCompleted: _completeActiveOrder,
          onCancelled: _cancelActiveOrder,
        ),
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
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon:
                    Icon(Icons.local_shipping, color: AppColors.primary),
                label: 'Penjemputan'),
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
