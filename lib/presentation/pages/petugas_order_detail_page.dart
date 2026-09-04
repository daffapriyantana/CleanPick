import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PetugasOrderDetailPage extends StatefulWidget {
  final String customerName;
  final String address;
  final String distance;
  final String wasteType;
  final String vehicleType;
  final String vehicleFee;
  final String distanceFee;
  final String total;
  final VoidCallback? onCompleted;
  final VoidCallback? onCancelled;

  const PetugasOrderDetailPage({
    super.key,
    required this.customerName,
    required this.address,
    required this.distance,
    required this.wasteType,
    required this.vehicleType,
    required this.vehicleFee,
    required this.distanceFee,
    required this.total,
    this.onCompleted,
    this.onCancelled,
  });

  @override
  State<PetugasOrderDetailPage> createState() => _PetugasOrderDetailPageState();
}

class _PetugasOrderDetailPageState extends State<PetugasOrderDetailPage> {
  bool _cancellationRequested = false;
  String? _cancellationReason;

  Future<void> _requestCancellation() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alasan Pembatalan'),
        content: const _CancellationReasons(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );

    if (!mounted || reason == null) return;
    setState(() {
      _cancellationRequested = true;
      _cancellationReason = reason;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        _cancellationRequested ? 'Menunggu Konfirmasi' : 'Menuju Lokasi';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Panel(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Caption('ID Pesanan'),
                      SizedBox(height: 2),
                      Text('CP-98218A', style: _strongText),
                    ],
                  ),
                  _StatusPill(label: statusLabel),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Panel(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFDCEFE4),
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customerName, style: _strongText),
                        const SizedBox(height: 2),
                        const Text('Customer Premium', style: _smallText),
                      ],
                    ),
                  ),
                  _RoundAction(
                    icon: Icons.chat_bubble_outline,
                    tooltip: 'Kirim pesan',
                    onPressed: () =>
                        _showMessage(context, 'Pesan belum tersedia'),
                  ),
                  const SizedBox(width: 8),
                  _RoundAction(
                    icon: Icons.phone_outlined,
                    tooltip: 'Telepon pelanggan',
                    onPressed: () =>
                        _showMessage(context, 'Telepon belum tersedia'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Detail Pengambilan'),
                  const SizedBox(height: 10),
                  const _Caption('Alamat Lengkap'),
                  const SizedBox(height: 3),
                  Text(widget.address, style: _bodyText),
                  const SizedBox(height: 12),
                  _MapButton(
                      onPressed: () =>
                          _showMessage(context, 'Membuka navigasi ke lokasi')),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _DetailValue(
                              label: 'Jenis Sampah', value: widget.wasteType)),
                      Expanded(
                          child: _DetailValue(
                              label: 'Kendaraan', value: widget.vehicleType)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _PhotoPlaceholder()),
                      Expanded(
                        child: _DetailValue(
                            label: 'Catatan',
                            value: 'Sampah ada di depan pagar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Estimasi Biaya'),
                  const SizedBox(height: 8),
                  _CostRow('Tarif Jasa Kendaraan', widget.vehicleFee),
                  _CostRow(
                      'Biaya Jarak (${widget.distance})', widget.distanceFee),
                  const Divider(height: 18),
                  _CostRow('Total Pendapatan', widget.total, emphasized: true),
                  if (_cancellationRequested) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Alasan: $_cancellationReason',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showMessage(context, 'Membuka navigasi ke lokasi'),
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text('Navigasi'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _cancellationRequested || widget.onCompleted == null
                          ? null
                          : () {
                              widget.onCompleted!();
                              Navigator.of(context).pop();
                            },
                  child: const Text('Pesanan Selesai'),
                ),
              ),
            ],
          ),
        ),
      ),
      persistentFooterButtons: _cancellationRequested
          ? [
              const Text(
                'Menunggu customer mengonfirmasi pembatalan',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ]
          : [
              TextButton.icon(
                onPressed:
                    widget.onCancelled == null ? null : _requestCancellation,
                icon: const Icon(Icons.cancel_outlined, size: 17),
                label: const Text('Batalkan Pesanan'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CancellationReasons extends StatelessWidget {
  const _CancellationReasons();

  static const reasons = [
    'Kendaraan sedang bermasalah',
    'Lokasi tidak dapat dijangkau',
    'Jadwal penjemputan berubah',
    'Permintaan customer',
    'Alasan lainnya',
  ];

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: reasons
            .map(
              (reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.radio_button_unchecked,
                    color: AppColors.primary),
                title: Text(reason, style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.of(context).pop(reason),
              ),
            )
            .toList(),
      );
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _PanelTitle extends StatelessWidget {
  final String text;
  const _PanelTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: _strongText);
}

class _Caption extends StatelessWidget {
  final String text;
  const _Caption(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: _captionText);
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 9,
                fontWeight: FontWeight.w700)),
      );
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _RoundAction(
      {required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: const Color(0xFFD1FAE5)),
      );
}

class _MapButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _MapButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 66,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.map_outlined,
              color: AppColors.primary, size: 18),
          label: const Text('Lihat Peta Navigasi', style: _smallStrongText),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFF8FAFC),
            side: const BorderSide(color: AppColors.border),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
        ),
      );
}

class _DetailValue extends StatelessWidget {
  final String label;
  final String value;
  const _DetailValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _captionText),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(4)),
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Foto Sampah', style: _captionText),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 35,
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(5)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_outlined,
                    size: 14, color: AppColors.textSecondary),
                SizedBox(width: 3),
                Text('1 Foto',
                    style:
                        TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  const _CostRow(this.label, this.value, {this.emphasized = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: emphasized ? _strongText : _bodyText),
            Text(value,
                style: TextStyle(
                    color:
                        emphasized ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: emphasized ? 14 : 11)),
          ],
        ),
      );
}

const _strongText = TextStyle(
    fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
const _smallStrongText = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
const _bodyText = TextStyle(fontSize: 10, color: AppColors.textSecondary);
const _smallText = TextStyle(fontSize: 9, color: AppColors.textSecondary);
const _captionText = TextStyle(fontSize: 9, color: AppColors.textSecondary);
