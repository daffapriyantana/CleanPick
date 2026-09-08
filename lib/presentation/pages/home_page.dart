import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import '../widgets/loading_widget.dart';
import 'create_order_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';
import 'customer_support_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final _pages = const [
    _HomeTab(),
    OrdersPage(embedded: true),
    CustomerNotificationsPage(),
    ProfilePage(embedded: true)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _BottomNav(
          selectedIndex: _index,
          onSelected: (index) => setState(() => _index = index)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _BottomNav({required this.selectedIndex, required this.onSelected});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Beranda'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Pesanan'),
    (Icons.notifications_none_outlined, Icons.notifications, 'Notifikasi'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE9EEEB))),
          boxShadow: [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 12, offset: Offset(0, -2))
          ],
        ),
        child: Row(children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(i),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(i == selectedIndex ? _items[i].$2 : _items[i].$1,
                          size: 20,
                          color: i == selectedIndex
                              ? AppColors.primary
                              : const Color(0xFF9CA5A0)),
                      const SizedBox(height: 4),
                      Text(_items[i].$3,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: i == selectedIndex
                                  ? AppColors.primary
                                  : const Color(0xFF9CA5A0))),
                    ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: () => context.read<OrderCubit>().loadOrders(),
        child: ListView(padding: EdgeInsets.zero, children: [
          _Header(name: _greetName(context), address: _userAddress(context)),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CreateOrderPage()))),
                    const SizedBox(height: 18),
                    const _SectionTitle('Kategori Sampah'),
                    const SizedBox(height: 9),
                    const _CategoryGrid(),
                    const SizedBox(height: 18),
                    _SectionTitle('Pesanan Aktif',
                        action: 'Menuju Lokasi', onAction: () => _selectTab(1)),
                    const SizedBox(height: 8),
                    BlocBuilder<OrderCubit, OrderState>(
                        builder: (context, state) {
                      if (state is OrderLoading) {
                        return const Padding(
                            padding: EdgeInsets.all(20),
                            child: LoadingWidget());
                      }
                      if (state is! OrdersLoaded) {
                        return const SizedBox.shrink();
                      }
                      final active = state.orders
                          .where((order) =>
                              order.status != OrderStatus.selesai &&
                              order.status != OrderStatus.dibatalkan)
                          .toList();
                      final recent = state.orders
                          .where((order) => order.status == OrderStatus.selesai)
                          .toList();
                      return Column(children: [
                        if (active.isEmpty)
                          const _EmptyOrder(text: 'Belum ada pesanan aktif')
                        else
                          ...active
                              .map((order) => _ActiveOrderCard(order: order)),
                        const SizedBox(height: 18),
                        _SectionTitle('Riwayat Terakhir',
                            action: 'Lihat Semua',
                            onAction: () => _selectTab(2)),
                        const SizedBox(height: 8),
                        if (recent.isEmpty)
                          const _EmptyOrder(text: 'Belum ada riwayat pesanan')
                        else
                          _RecentOrderCard(order: recent.first),
                      ]);
                    }),
                  ])),
        ]),
      ),
    );
  }

  void _selectTab(int index) {
    final homeState = context.findAncestorStateOfType<_HomePageState>();
    homeState?.setState(() => homeState._index = index);
  }

  String _greetName(BuildContext context) {
    final state = context.read<AuthCubit>().state;
    return state is AuthSuccess ? state.user.name : 'Pelanggan';
  }

  String _userAddress(BuildContext context) {
    final state = context.read<AuthCubit>().state;
    if (state is AuthSuccess && state.user.address.trim().isNotEmpty) {
      return state.user.address;
    }
    return 'Mulyorejo, Kec. Sukolilo';
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String address;
  const _Header({required this.name, required this.address});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primaryDark,
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.paddingOf(context).top + 13, 16, 16),
        child: Row(children: [
          const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF4A9D68),
              child: Icon(Icons.person, color: Colors.white, size: 23)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Halo, $name!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10)),
              ])),
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_on_outlined,
                  color: Colors.white, size: 21)),
        ]),
      );
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onPressed;
  const _HeroCard({required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
        height: 130,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x250F5C2D),
                  blurRadius: 10,
                  offset: Offset(0, 5))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pesan Pengambilan Sampah',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Pilih jadwal pengumpulan sekarang dan bantu\nbersihkan lingkungan kita.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 10, height: 1.3)),
          SizedBox(
              height: 30,
              child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Pesan Sekarang',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700)))),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionTitle(this.title, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        if (action != null)
          TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(action!,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600))),
      ]);
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();
  @override
  Widget build(BuildContext context) => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.65,
          children: const [
            _CategoryCard('Organik', Icons.eco_outlined, Color(0xFFE7F5EA),
                Color(0xFF35A875)),
            _CategoryCard('Anorganik', Icons.local_drink_outlined,
                Color(0xFFE5F2FC), Color(0xFF4C9AD8)),
            _CategoryCard('B3 (Bahaya)', Icons.warning_amber_outlined,
                Color(0xFFFDE9ED), Color(0xFFE36D7C)),
            _CategoryCard('Daur Ulang', Icons.recycling_outlined,
                Color(0xFFFFF6DD), Color(0xFFD59B28)),
          ]);
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color iconColor;
  const _CategoryCard(this.label, this.icon, this.background, this.iconColor);
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(11)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: iconColor, size: 26),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600))
      ]));
}

class _ActiveOrderCard extends StatelessWidget {
  final OrderEntity order;
  const _ActiveOrderCard({required this.order});
  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, HH:mm', 'id_ID').format(order.pickupDate);
    return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x08000000), blurRadius: 5, offset: Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.local_shipping_outlined,
                color: AppColors.primary, size: 19),
            SizedBox(width: 7),
            Expanded(
                child: Text('Layanan Pickup',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            _SmallBadge('Menuju Lokasi', Color(0xFFE5F2FC), Color(0xFF3985C2))
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(date,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
            Text('Petugas: ${order.officerName ?? 'Menunggu'}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10))
          ]),
          const SizedBox(height: 9),
          const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(
                  value: .7,
                  minHeight: 5,
                  backgroundColor: Color(0xFFE8EDEB),
                  valueColor: AlwaysStoppedAnimation(AppColors.primary))),
          const SizedBox(height: 6),
          const Text('Petugas sedang menuju lokasi Anda',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
        ]));
  }
}

class _RecentOrderCard extends StatelessWidget {
  final OrderEntity order;
  const _RecentOrderCard({required this.order});
  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(order.pickupDate);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: const Color(0xFFE7F5EA),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.eco_outlined,
                  color: AppColors.primary, size: 21)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Pickup Sampah ${order.wasteType.label}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(date,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 9))
              ])),
          const _SmallBadge('Selesai', Color(0xFFE7F5EA), AppColors.primary)
        ]));
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  const _SmallBadge(this.label, this.background, this.foreground);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              color: foreground, fontSize: 9, fontWeight: FontWeight.w700)));
}

class _EmptyOrder extends StatelessWidget {
  final String text;
  const _EmptyOrder({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border)),
      child: Text(text,
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 10)));
}
