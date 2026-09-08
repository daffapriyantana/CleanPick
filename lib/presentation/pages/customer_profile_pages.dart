import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});
  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  final List<String> _addresses = [
    'Rumah - Jl. Melati No. 12, Jakarta Selatan'
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Alamat Tersimpan')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._addresses.map((address) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                    title: Text(address),
                    trailing: IconButton(
                      tooltip: 'Edit alamat',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editAddress(address),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _editAddress(null),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Alamat'),
            ),
          ],
        ),
      );

  Future<void> _editAddress(String? oldAddress) async {
    final controller = TextEditingController(text: oldAddress);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(oldAddress == null ? 'Tambah Alamat' : 'Edit Alamat'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Nama tempat dan alamat lengkap'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Simpan')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    setState(() {
      if (oldAddress != null) {
        _addresses[_addresses.indexOf(oldAddress)] = result;
      } else {
        _addresses.add(result);
      }
    });
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool order = true;
  bool promo = true;
  bool sound = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Notifikasi')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Atur notifikasi yang ingin Anda terima',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _switch('Status Pesanan', 'Terima pembaruan status pickup',
                      order, (value) => setState(() => order = value)),
                  const Divider(height: 1),
                  _switch('Promo dan Info', 'Dapatkan info dan tips CleanPick',
                      promo, (value) => setState(() => promo = value)),
                  const Divider(height: 1),
                  _switch('Suara Notifikasi', 'Bunyikan notifikasi baru', sound,
                      (value) => setState(() => sound = value)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _switch(String title, String subtitle, bool value,
          ValueChanged<bool> onChanged) =>
      SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        title: Text(title),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      );
}

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bantuan & FAQ')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Pertanyaan Umum',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...[
              'Bagaimana cara membuat pesanan?',
              'Bagaimana cara mengubah jadwal pickup?',
              'Bagaimana metode pembayaran COD?',
              'Bagaimana cara menghubungi petugas?',
            ].map((question) => ExpansionTile(
                  title: Text(question, style: const TextStyle(fontSize: 13)),
                  children: const [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                          'Tim CleanPick akan membantu Anda melalui alur pesanan yang tersedia.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                )),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text('Hubungi Admin'),
                  content: Text(
                      'Chat Anda akan diteruskan ke dashboard admin CleanPick.'),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Hubungi Kami'),
            ),
          ],
        ),
      );
}
