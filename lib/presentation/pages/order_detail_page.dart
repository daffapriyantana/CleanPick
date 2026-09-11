import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/status_badge.dart';
import 'customer_support_pages.dart';
import 'finding_officer_page.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>
    with WidgetsBindingObserver {
  PaymentMethod? _selectedPaymentMethod;
  bool _checkoutOpened = false;
  bool _paymentRefreshInProgress = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<OrderCubit>().loadOrderDetail(widget.orderId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkoutOpened && mounted) {
      _refreshAfterCheckout();
    }
  }

  Future<void> _refreshAfterCheckout() async {
    if (_paymentRefreshInProgress || !mounted) return;
    _paymentRefreshInProgress = true;
    final orderCubit = context.read<OrderCubit>();

    try {
      // Android can report resumed while the external browser is still
      // handing control back to the app. Give Midtrans time to finish first.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      var paid = false;
      for (var attempt = 0; attempt < 10 && mounted; attempt++) {
        await orderCubit.refreshPaymentStatus(widget.orderId);
        await orderCubit.loadOrderDetail(widget.orderId);
        final state = orderCubit.state;
        if (state is OrderDetailLoaded &&
            state.order.paymentStatus == PaymentStatus.lunas) {
          paid = true;
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      _checkoutOpened = false;
      if (mounted && !paid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pembayaran belum terkonfirmasi. Tekan bayar lagi untuk memeriksa ulang.',
            ),
          ),
        );
      }
    } finally {
      _paymentRefreshInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pesanan berhasil dibatalkan')),
            );
          } else if (state is PaymentCheckoutReady) {
            _openCheckout(state.checkout.redirectUrl);
          }
        },
        builder: (context, state) {
          if (state is OrderLoading) return const LoadingWidget();
          if (state is OrderFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<OrderCubit>().loadOrderDetail(widget.orderId),
            );
          }

          final order = state is OrderDetailLoaded
              ? state.order
              : state is OrderCancelled
                  ? state.order
                  : state is OrderPaid
                      ? state.order
                      : state is PaymentCheckoutReady
                          ? state.order
                          : null;
          if (order == null) return const SizedBox.shrink();
          _selectedPaymentMethod ??= order.paymentMethod;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.id,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DETAIL PENGAMBILAN',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _infoRow('Alamat', order.address),
                        _infoRow(
                            'Jenis Sampah',
                            order.selectedWasteTypes
                                .map((type) => type.label)
                                .join(', ')),
                        _infoRow(
                            'Berat', '${order.weightKg.toStringAsFixed(1)} kg'),
                        _infoRow('Kendaraan', order.vehicleType.label),
                        _infoRow('Tanggal', dateFmt.format(order.pickupDate)),
                        if (order.officerName != null)
                          _infoRow('Petugas', order.officerName!),
                        if (order.note != null && order.note!.isNotEmpty)
                          _infoRow('Catatan', order.note!),
                        if (order.photoPath != null) ...[
                          const SizedBox(height: 8),
                          const Text('Foto untuk Petugas',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => FullscreenPhotoPage(
                                          photoPath: order.photoPath!))),
                              child: Image.file(File(order.photoPath!),
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => FullscreenPhotoPage(
                                        photoPath: order.photoPath!))),
                            icon: const Icon(Icons.fullscreen),
                            label: const Text('Lihat Foto Penuh'),
                          ),
                        ],
                        if (order.latitude != null &&
                            order.longitude != null) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openMap(order.latitude!, order.longitude!),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Lihat Titik Lokasi di Maps'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (order.officerName != null &&
                    order.status != OrderStatus.dibatalkan) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(order.officerName!,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Petugas CleanPick'),
                      trailing: Wrap(spacing: 4, children: [
                        IconButton(
                            tooltip: 'Chat petugas',
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => OfficerChatPage(
                                        officerName: order.officerName!,
                                        orderId: order.id))),
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: AppColors.primary)),
                        IconButton(
                            tooltip: 'Telepon petugas',
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => OfficerCallPage(
                                        officerName: order.officerName!))),
                            icon: const Icon(Icons.phone_outlined,
                                color: AppColors.primary)),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                    child: ListTile(
                        leading: const Icon(Icons.payments_outlined,
                            color: AppColors.primary),
                        title: const Text('Metode Pembayaran',
                            style: TextStyle(fontSize: 12)),
                        subtitle: Text(order.paymentMethod.label))),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RINCIAN BIAYA',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _infoRow(
                            'Tarif Kendaraan', currency.format(order.baseFee)),
                        _infoRow(
                            'Biaya Sampah', currency.format(order.weightFee)),
                        _infoRow(
                            'Biaya Jarak', currency.format(order.distanceFee)),
                        const Divider(),
                        _infoRow(
                            'Total Biaya', currency.format(order.totalPrice),
                            bold: true),
                        _infoRow('Status Bayar', order.paymentStatus.label),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (order.status == OrderStatus.menunggu ||
                    order.status == OrderStatus.diproses)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(48)),
                    onPressed: () =>
                        context.read<OrderCubit>().cancel(order.id),
                    child: const Text('Batalkan Pesanan'),
                  ),
                _buildPaymentAction(order),
                if (order.status == OrderStatus.selesai) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => OfficerRatingPage(
                                officerName:
                                    order.officerName ?? 'Petugas CleanPick'))),
                    icon: const Icon(Icons.star_border),
                    label: const Text('Beri Rating & Keluhan'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aplikasi Maps tidak tersedia')),
      );
    }
  }

  Future<void> _openCheckout(String redirectUrl) async {
    _checkoutOpened = true;
    final opened = await launchUrl(
      Uri.parse(redirectUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _checkoutOpened = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman pembayaran tidak tersedia')),
      );
    }
  }

  String _virtualAccount(OrderEntity order) {
    final bank = order.paymentMethod.label.replaceFirst('Virtual Account ', '');
    return '8808 1200 ${order.id.hashCode.abs() % 1000000} ($bank)';
  }

  Widget _buildPaymentAction(OrderEntity order) {
    final isOnline = order.paymentMethod.requiresOnlinePayment;
    final isPaid = order.paymentStatus == PaymentStatus.lunas;
    final statusColor = isPaid ? AppColors.primary : Colors.orange.shade800;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: isPaid ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPaid ? Icons.verified_outlined : Icons.payments_outlined,
                  color: statusColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPaid ? 'Pembayaran berhasil' : 'Pembayaran pesanan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline
                            ? order.paymentMethod.label
                            : 'Bayar kepada petugas saat tiba di lokasi',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  order.paymentStatus.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (isOnline && !isPaid) ...[
              const SizedBox(height: 12),
              Text(
                'Total ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.totalPrice)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (order.paymentMethod != PaymentMethod.codQris &&
                  order.paymentMethod != PaymentMethod.transfer) ...[
                const SizedBox(height: 4),
                Text(
                  'Kode Virtual Account: ${_virtualAccount(order)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              if (order.paymentMethod == PaymentMethod.transfer) ...[
                const SizedBox(height: 4),
                const Text(
                  'Pembayaran akan diproses melalui Midtrans.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<OrderCubit>().pay(order.id),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Bayar dengan Midtrans'),
                ),
              ),
            ],
            if (isOnline && isPaid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FindingOfficerPage(orderId: order.id),
                    ),
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Cari Petugas'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: bold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
