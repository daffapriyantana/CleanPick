import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PetugasOrdersView extends StatefulWidget {
  final ValueChanged<String> onMessage;
  const PetugasOrdersView({super.key, required this.onMessage});

  @override
  State<PetugasOrdersView> createState() => _PetugasOrdersViewState();
}

class _PetugasOrdersViewState extends State<PetugasOrdersView> {
  bool _showCompleted = false;
  final Set<String> _handledOrders = <String>{};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pesanan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _TabButton(
                          label: 'Aktif',
                          selected: !_showCompleted,
                          onPressed: () =>
                              setState(() => _showCompleted = false))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _TabButton(
                          label: 'Selesai',
                          selected: _showCompleted,
                          onPressed: () =>
                              setState(() => _showCompleted = true))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            child: _showCompleted ? _completedOrders() : _activeOrders(),
          ),
        ),
      ],
    );
  }

  Widget _activeOrders() {
    final orders = [
      const _OrderData(
          name: 'Budi Santoso',
          time: '5 menit yang lalu',
          distance: '2.3 km',
          location: 'Pondok Indah Mall, Area Pick-up Utara',
          categories: ['Plastik', 'Kertas'],
          price: 'Rp 45.000'),
      const _OrderData(
          name: 'Dewi Lestari',
          time: '10 menit yang lalu',
          distance: '4.1 km',
          location: 'Jl. Melati Indah No. 12, Cilandak',
          categories: ['Organik'],
          price: 'Rp 30.000'),
    ];
    final visibleOrders =
        orders.where((order) => !_handledOrders.contains(order.name)).toList();
    if (visibleOrders.isEmpty) {
      return const _EmptyOrders(message: 'Tidak ada pesanan aktif');
    }
    return Column(
        children: visibleOrders
            .map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActiveOrderCard(order: order, onAction: _handleOrder)))
            .toList());
  }

  Widget _completedOrders() {
    const orders = [
      _OrderData(
          name: 'Budi Santoso',
          time: 'Hari ini, 14:20',
          location: 'Pondok Indah Mall, Area Pick-up Utara',
          categories: ['Plastik', 'Kertas'],
          price: 'Rp 45.000'),
      _OrderData(
          name: 'Siti Rahma',
          time: 'Hari ini, 10:15',
          location: 'Jl. Melati Indah No. 12, Cilandak',
          categories: ['Organik'],
          price: 'Rp 30.000'),
      _OrderData(
          name: 'Hendra Wijaya',
          time: 'Kemarin, 16:45',
          location: 'Kebayoran Heights Block C-5',
          categories: ['Plastik', 'Kaca', 'Logam'],
          price: 'Rp 65.000'),
    ];
    return Column(
        children: orders
            .map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompletedOrderCard(order: order)))
            .toList());
  }

  void _handleOrder(String name, bool accepted) {
    setState(() => _handledOrders.add(name));
    widget.onMessage(
        accepted ? 'Pesanan $name diterima' : 'Pesanan $name ditolak');
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  const _TabButton(
      {required this.label, required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? AppColors.primary : Colors.transparent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _OrderData {
  final String name;
  final String time;
  final String? distance;
  final String location;
  final List<String> categories;
  final String price;
  const _OrderData(
      {required this.name,
      required this.time,
      this.distance,
      required this.location,
      required this.categories,
      required this.price});
}

class _ActiveOrderCard extends StatelessWidget {
  final _OrderData order;
  final void Function(String, bool) onAction;
  const _ActiveOrderCard({required this.order, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return _OrderCardFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(order.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold))),
          Text('• ${order.time}',
              style:
                  const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Text(order.distance!,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        _LocationText(order.location),
        const SizedBox(height: 9),
        _CategoryWrap(categories: order.categories, includeMotor: true),
        const Divider(height: 20),
        Row(children: [
          Text(order.price,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const Spacer(),
          OutlinedButton(
              onPressed: () => onAction(order.name, false),
              style: _smallButtonStyle(AppColors.error),
              child: const Text('Tolak')),
          const SizedBox(width: 7),
          ElevatedButton(
              onPressed: () => onAction(order.name, true),
              style: _smallButtonStyle(Colors.white),
              child: const Text('Terima')),
        ]),
      ]),
    );
  }
}

class _CompletedOrderCard extends StatelessWidget {
  final _OrderData order;
  const _CompletedOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _OrderCardFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(order.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold))),
          Text('• ${order.time}',
              style:
                  const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          const _StatusPill(),
        ]),
        const SizedBox(height: 11),
        _LocationText(order.location),
        const SizedBox(height: 9),
        _CategoryWrap(categories: order.categories),
        const Divider(height: 20),
        Row(children: [
          const Text('Pendapatan',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const Spacer(),
          Text(order.price,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

class _OrderCardFrame extends StatelessWidget {
  final Widget child;
  const _OrderCardFrame({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000), blurRadius: 5, offset: Offset(0, 2))
            ]),
        child: child,
      );
}

class _LocationText extends StatelessWidget {
  final String location;
  const _LocationText(this.location);

  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.location_on_outlined,
            size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
            child: Text(location,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary))),
      ]);
}

class _CategoryWrap extends StatelessWidget {
  final List<String> categories;
  final bool includeMotor;
  const _CategoryWrap({required this.categories, this.includeMotor = false});

  @override
  Widget build(BuildContext context) {
    final values = [...categories, if (includeMotor) 'Motor'];
    return Wrap(
        spacing: 5,
        runSpacing: 4,
        children: values.map((value) => _CategoryPill(value)).toList());
  }
}

class _CategoryPill extends StatelessWidget {
  final String value;
  const _CategoryPill(this.value);

  @override
  Widget build(BuildContext context) {
    final isVehicle = value == 'Motor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: isVehicle ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isVehicle)
          const Icon(Icons.two_wheeler, size: 12, color: Color(0xFF2563EB)),
        if (isVehicle) const SizedBox(width: 3),
        Text(value,
            style: TextStyle(
                fontSize: 9,
                color: isVehicle
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF15803D),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12)),
      child: const Text('Selesai',
          style: TextStyle(
              fontSize: 9,
              color: Color(0xFF15803D),
              fontWeight: FontWeight.bold)));
}

class _EmptyOrders extends StatelessWidget {
  final String message;
  const _EmptyOrders({required this.message});

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message,
              style: const TextStyle(color: AppColors.textSecondary))));
}

ButtonStyle _smallButtonStyle(Color foreground) => ElevatedButton.styleFrom(
    foregroundColor: foreground,
    backgroundColor:
        foreground == Colors.white ? AppColors.primary : Colors.white,
    minimumSize: const Size(68, 34),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    side: foreground == AppColors.error
        ? const BorderSide(color: AppColors.error)
        : null,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
