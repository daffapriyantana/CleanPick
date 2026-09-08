import 'package:flutter/material.dart';
import 'dart:io';

import '../../core/theme/app_theme.dart';
import '../../core/services/app_event_store.dart';

class ComplaintStore {
  static final List<
          ({String customer, String complaint, String status, String category})>
      items = [
    (
      customer: 'Budi Santoso',
      complaint: 'Petugas terlambat datang',
      status: 'Baru',
      category: 'Pelayanan'
    ),
    (
      customer: 'Siti Rahma',
      complaint: 'Sampah anorganik tidak diangkut',
      status: 'Diproses',
      category: 'Operasional'
    ),
  ];
}

class CustomerNotificationsPage extends StatefulWidget {
  const CustomerNotificationsPage({super.key});

  static const items = [
    (
      'Pesanan Diterima',
      'Pesanan Anda telah masuk sistem.',
      Icons.check_circle_outline
    ),
    (
      'Petugas Ditemukan',
      'Ahmad Supardi ditugaskan mengambil sampah Anda.',
      Icons.person_outline
    ),
    (
      'Petugas Menuju Lokasi',
      'Petugas dalam perjalanan ke lokasi pickup.',
      Icons.near_me_outlined
    ),
    (
      'Sampah Diambil',
      'Sampah Anda telah berhasil diambil.',
      Icons.local_shipping_outlined
    ),
    (
      'Pesanan Selesai',
      'Terima kasih! Berikan ulasan Anda.',
      Icons.star_border
    ),
    (
      'Info CleanPick',
      'Tips memilah sampah plastik dan kertas.',
      Icons.info_outline
    ),
  ];

  @override
  State<CustomerNotificationsPage> createState() =>
      _CustomerNotificationsPageState();
}

class _CustomerNotificationsPageState extends State<CustomerNotificationsPage> {
  @override
  void initState() {
    super.initState();
    AppNotificationStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppNotificationStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final notifications = AppNotificationStore.instance.items;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 9),
        itemBuilder: (_, index) => Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFD9F4E3),
              child: Icon(Icons.notifications_none, color: AppColors.primary),
            ),
            title: Text(notifications[index].title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            subtitle: Text(notifications[index].message,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            trailing:
                const Icon(Icons.circle, size: 7, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class OfficerChatPage extends StatefulWidget {
  final String officerName;
  final String orderId;
  final bool isOfficer;
  const OfficerChatPage(
      {super.key,
      this.officerName = 'Ahmad Supardi',
      this.orderId = 'demo-order',
      this.isOfficer = false});

  @override
  State<OfficerChatPage> createState() => _OfficerChatPageState();
}

class _OfficerChatPageState extends State<OfficerChatPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppChatStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppChatStore.instance.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(children: [
            const CircleAvatar(radius: 17, child: Icon(Icons.person, size: 18)),
            const SizedBox(width: 8),
            Text(widget.officerName),
          ]),
        ),
        body: Column(children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: AppChatStore.instance.forOrder(widget.orderId).length,
              itemBuilder: (_, index) => Align(
                alignment: AppChatStore.instance
                            .forOrder(widget.orderId)[index]
                            .sender ==
                        (widget.isOfficer ? 'Petugas' : 'Customer')
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppChatStore.instance
                                .forOrder(widget.orderId)[index]
                                .sender ==
                            (widget.isOfficer ? 'Petugas' : 'Customer')
                        ? const Color(0xFFD9F4E3)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(AppChatStore.instance
                      .forOrder(widget.orderId)[index]
                      .text),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: _controller,
                        decoration:
                            const InputDecoration(hintText: 'Tulis pesan...'))),
                IconButton(
                  tooltip: 'Kirim',
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) return;
                    AppChatStore.instance.send(
                        orderId: widget.orderId,
                        sender: widget.isOfficer ? 'Petugas' : 'Customer',
                        text: _controller.text);
                    _controller.clear();
                  },
                ),
              ]),
            ),
          ),
        ]),
      );
}

class OfficerCallPage extends StatelessWidget {
  final String officerName;
  const OfficerCallPage({super.key, this.officerName = 'Ahmad Supardi'});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Telepon Petugas')),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 52)),
            const SizedBox(height: 16),
            Text(officerName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 5),
            const Text('Memanggil petugas CleanPick...',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 28),
            IconButton.filled(
              tooltip: 'Akhiri telepon',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.call_end),
              style: IconButton.styleFrom(backgroundColor: AppColors.error),
            ),
          ]),
        ),
      );
}

class OfficerRatingPage extends StatefulWidget {
  final String officerName;
  const OfficerRatingPage({super.key, this.officerName = 'Ahmad Supardi'});

  @override
  State<OfficerRatingPage> createState() => _OfficerRatingPageState();
}

class _OfficerRatingPageState extends State<OfficerRatingPage> {
  int _rating = 0;
  final _complaint = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nilai Petugas')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Bagaimana layanan ${widget.officerName}?',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 18),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (index) => IconButton(
                        tooltip: '${index + 1} bintang',
                        onPressed: () => setState(() => _rating = index + 1),
                        icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36),
                      ))),
          const SizedBox(height: 18),
          const Text('Ada keluhan untuk petugas?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
              controller: _complaint,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'Tulis keluhan atau masukan Anda...')),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _rating == 0
                ? null
                : () {
                    if (_complaint.text.trim().isNotEmpty) {
                      ComplaintStore.items.add((
                        customer: 'Customer CleanPick',
                        complaint: _complaint.text.trim(),
                        status: 'Baru',
                        category: 'Pelayanan',
                      ));
                    }
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Rating dan keluhan berhasil dikirim')));
                    Navigator.of(context).pop();
                  },
            child: const Text('Kirim Penilaian'),
          ),
        ]),
      );
}

class CustomerInfoPage extends StatelessWidget {
  final String title;
  final String content;
  const CustomerInfoPage(
      {super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(content,
              style:
                  const TextStyle(height: 1.6, color: AppColors.textSecondary))
        ]),
      );
}

class FullscreenPhotoPage extends StatelessWidget {
  final String photoPath;
  const FullscreenPhotoPage({super.key, required this.photoPath});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Foto Sampah'),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.file(File(photoPath), fit: BoxFit.contain),
          ),
        ),
      );
}
