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
import '../widgets/status_badge.dart';
import 'create_order_page.dart';
import 'history_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

/// Home shell with Bottom Navigation, matching the design's tab set:
/// Beranda / Pesanan / Notifikasi(→ history) / Profil.
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
    HistoryPage(embedded: true),
    ProfilePage(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
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
      child: RefreshIndicator(
        onRefresh: () => context.read<OrderCubit>().loadOrders(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 22, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, ${_greetName(context)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Selamat datang kembali', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesan Pengambilan Sampah',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Pesan jadwal penjemputan sekarang dan bantu lingkungan bersih.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateOrderPage()),
                      ),
                      child: const Text('Pesan Sekarang'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Kategori Sampah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: const [
                _CategoryChip(label: 'Organik', icon: Icons.eco_outlined, color: Color(0xFF16A34A)),
                _CategoryChip(label: 'Anorganik', icon: Icons.delete_outline, color: Color(0xFF3B82F6)),
                _CategoryChip(label: 'B3 (Bahaya)', icon: Icons.warning_amber_outlined, color: Color(0xFFDC2626)),
                _CategoryChip(label: 'Daur Ulang', icon: Icons.autorenew, color: Color(0xFFF5A524)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pesanan Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                TextButton(
                  onPressed: () {
                    final state = context.findAncestorStateOfType<_HomePageState>();
                    state?.setState(() => state._index = 1);
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                if (state is OrderLoading) return const Padding(padding: EdgeInsets.all(24), child: LoadingWidget());
                if (state is OrdersLoaded) {
                  final active = state.orders
                      .where((o) => o.status != OrderStatus.selesai && o.status != OrderStatus.dibatalkan)
                      .toList();
                  if (active.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Belum ada pesanan aktif', style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return Column(children: active.map((o) => _ActiveOrderTile(order: o)).toList());
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _greetName(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) return authState.user.name;
    return 'Pelanggan';
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

class _ActiveOrderTile extends StatelessWidget {
  final OrderEntity order;
  const _ActiveOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM, HH:mm', 'id_ID');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Layanan Pickup', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(dateFmt.format(order.pickupDate), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            StatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }
}
