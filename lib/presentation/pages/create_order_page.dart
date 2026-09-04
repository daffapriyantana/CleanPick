import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/usecases/calculate_order_price.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';
import 'order_detail_page.dart';

/// The "Buat Pesanan" page -- this is where BLoC/Cubit state
/// management is showcased most heavily, per the milestone spec:
/// Initial -> Loading -> Success/Failure driven entirely by
/// [OrderCubit].
class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _addressController = TextEditingController(
      text: 'Jl. Melati No. 12, RT 05/RW 03, Jakarta Selatan');
  final _weightController = TextEditingController(text: '10');
  final _noteController = TextEditingController();

  WasteType? _wasteType = WasteType.organik;
  VehicleType _vehicleType = VehicleType.motorRoda3;
  DateTime? _pickupDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalculate());
  }

  void _recalculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (_wasteType == null || weight <= 0) return;
    context.read<OrderCubit>().previewPrice(
          weightKg: weight,
          wasteType: _wasteType!,
          vehicleType: _vehicleType,
        );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan Pengambilan')),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => OrderDetailPage(orderId: state.order.id)),
            );
          } else if (state is OrderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is OrderLoading;
          final priceResult = state is OrderPricePreview ? state.price : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('Alamat Pengambilan'),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      hintText: 'Masukkan alamat pengambilan'),
                  onChanged: (_) => _recalculate(),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Jenis Sampah'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WasteType.values.map((type) {
                    final selected = _wasteType == type;
                    return ChoiceChip(
                      label: Text(type.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _wasteType = type);
                        _recalculate();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Berat Sampah (kg)'),
                TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      hintText: 'contoh: 10', suffixText: 'kg'),
                  onChanged: (_) => _recalculate(),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Pilih Kendaraan'),
                RadioGroup<VehicleType>(
                  groupValue: _vehicleType,
                  onChanged: (val) {
                    setState(() => _vehicleType = val!);
                    _recalculate();
                  },
                  child: Column(
                    children: VehicleType.values.map((v) {
                      final selected = _vehicleType == v;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 1.5 : 1),
                        ),
                        child: RadioListTile<VehicleType>(
                          value: v,
                          title: Text(v.label),
                          subtitle: Text(
                              'Kapasitas hingga ${v.maxCapacityKg >= 100000 ? '1000+' : v.maxCapacityKg.toStringAsFixed(0)} kg'),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Tanggal Pengangkutan'),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) setState(() => _pickupDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today_outlined)),
                    child: Text(
                      _pickupDate == null
                          ? 'Pilih tanggal'
                          : DateFormat('dd MMMM yyyy', 'id_ID')
                              .format(_pickupDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Catatan untuk Petugas (Opsional)'),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                      hintText: 'Contoh: Sampah ada di depan pagar...'),
                ),
                const SizedBox(height: 20),
                if (priceResult != null) _EstimateCard(price: priceResult),
                if (state is OrderFailure && priceResult == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(state.message,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          context.read<OrderCubit>().submitOrder(
                                wasteType: _wasteType,
                                weightKg:
                                    double.tryParse(_weightController.text) ??
                                        0,
                                address: _addressController.text,
                                pickupDate: _pickupDate,
                                vehicleType: _vehicleType,
                                note: _noteController.text.isEmpty
                                    ? null
                                    : _noteController.text,
                              );
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Pesan Sekarang'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      );
}

class _EstimateCard extends StatelessWidget {
  final OrderPriceResult price;
  const _EstimateCard({required this.price});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estimasi Biaya',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('Tarif Kendaraan', currency.format(price.baseFee)),
          _row('Biaya Sampah', currency.format(price.weightFee)),
          _row('Biaya Jarak', currency.format(price.distanceFee)),
          const Divider(),
          _row('Total Estimasi', currency.format(price.total), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 15 : 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: style.copyWith(
                  color:
                      bold ? AppColors.textPrimary : AppColors.textSecondary)),
          Text(value,
              style: style.copyWith(
                  color: bold ? AppColors.primary : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
