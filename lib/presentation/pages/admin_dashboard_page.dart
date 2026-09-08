import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'customer_support_pages.dart';
import '../../core/services/app_event_store.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('Customer', '1,245', Icons.people_outline),
      ('Petugas', '48', Icons.person_outline),
      ('Aktif', '23', Icons.local_shipping_outlined),
      ('Selesai', '3,891', Icons.check_box_outlined),
      ('Pendapatan', 'Rp 12.5jt', Icons.monetization_on_outlined),
    ];
    final menus = [
      ('Customer', Icons.people_outline, () {}),
      ('Petugas', Icons.person_outline, () {}),
      ('Kendaraan', Icons.local_shipping_outlined, () {}),
      ('Pesanan', Icons.assignment_outlined, () {}),
      ('Tarif', Icons.attach_money, () {}),
      ('Pembayaran', Icons.payments_outlined, () {}),
      ('Laporan', Icons.bar_chart, () {}),
      (
        'Keluhan',
        Icons.warning_amber_outlined,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminComplaintsPage()))
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
          backgroundColor: const Color(0xFF3A9A70),
          foregroundColor: Colors.white,
          title: const Text('Dashboard Admin'),
          actions: [
            IconButton(
                tooltip: 'Notifikasi',
                onPressed: () => _showNoticeDialog(context),
                icon: const Icon(Icons.notifications_none))
          ]),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const Text('Statistik Operasional',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats
                .map((stat) =>
                    _Stat(label: stat.$1, value: stat.$2, icon: stat.$3))
                .toList()),
        const SizedBox(height: 18),
        const Text('Menu Kelola',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: menus
                .map((menu) =>
                    _AdminMenu(icon: menu.$2, label: menu.$1, onTap: menu.$3))
                .toList()),
        const SizedBox(height: 18),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ringkasan Pesanan (Mingguan)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 18),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [40, 58, 78, 62, 92, 105, 50]
                              .asMap()
                              .entries
                              .map((entry) => Column(children: [
                                    Container(
                                        width: 22,
                                        height: entry.value.toDouble(),
                                        decoration: BoxDecoration(
                                            color: entry.key == 5
                                                ? AppColors.primary
                                                : const Color(0xFFD7F2E2),
                                            borderRadius:
                                                BorderRadius.circular(4))),
                                    const SizedBox(height: 4),
                                    Text(
                                        [
                                          'Sen',
                                          'Sel',
                                          'Rab',
                                          'Kam',
                                          'Jum',
                                          'Sab',
                                          'Min'
                                        ][entry.key],
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: AppColors.textSecondary))
                                  ]))
                              .toList()),
                    ]))),
      ]),
    );
  }

  Future<void> _showNoticeDialog(BuildContext context) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Pemberitahuan'),
        content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Tulis informasi untuk customer')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Kirim')),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.isEmpty) return;
    AppNotificationStore.instance.addAdminNotice(message);
  }
}

class AdminComplaintsPage extends StatelessWidget {
  const AdminComplaintsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Keluhan Pelanggan'),
            backgroundColor: const Color(0xFF3A9A70),
            foregroundColor: Colors.white),
        body: ListView(padding: const EdgeInsets.all(14), children: [
          TextField(
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Cari nama, keluhan, atau kategori...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          ...ComplaintStore.items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(item.customer,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                          _Status(label: item.status)
                        ]),
                        const SizedBox(height: 5),
                        Text(item.complaint,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text('12 Jan 2024 • 14:30',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textSecondary)),
                        const Divider(height: 18),
                        Row(children: [
                          Text(item.category,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                          const Spacer(),
                          TextButton(
                              onPressed: () {},
                              child: const Text('Lihat Detail'))
                        ]),
                      ])))),
        ]),
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 158,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary)),
                    Text(value,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _AdminMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AdminMenu(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 5),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9))
          ])));
}

class _Status extends StatelessWidget {
  final String label;
  const _Status({required this.label});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: label == 'Baru'
              ? const Color(0xFFFFE0E0)
              : const Color(0xFFD7F2E2),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              color: label == 'Baru' ? AppColors.error : AppColors.primary,
              fontWeight: FontWeight.bold)));
}
