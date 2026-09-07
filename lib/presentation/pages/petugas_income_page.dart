import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order/order_cubit.dart';
import '../bloc/order/order_state.dart';

class PetugasIncomeView extends StatefulWidget {
  const PetugasIncomeView({super.key});

  @override
  State<PetugasIncomeView> createState() => _PetugasIncomeViewState();
}

class _PetugasIncomeViewState extends State<PetugasIncomeView> {
  bool _isMonthly = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pendapatan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: const Color(0xFF0F3B25),
                    borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    Expanded(
                        child: _PeriodButton(
                            label: 'Mingguan',
                            selected: !_isMonthly,
                            onPressed: () =>
                                setState(() => _isMonthly = false))),
                    Expanded(
                        child: _PeriodButton(
                            label: 'Bulanan',
                            selected: _isMonthly,
                            onPressed: () =>
                                setState(() => _isMonthly = true))),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _DynamicIncomeContent(isMonthly: _isMonthly),
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicIncomeContent extends StatelessWidget {
  final bool isMonthly;
  const _DynamicIncomeContent({required this.isMonthly});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        final orders = state is OrdersLoaded
            ? state.orders
                .where((order) => order.status == OrderStatus.selesai)
                .toList()
            : <OrderEntity>[];
        final now = DateTime.now();
        final filtered = orders.where((order) {
          final difference = now.difference(order.createdAt).inDays;
          return isMonthly ? difference < 31 : difference < 7;
        }).toList();
        final total =
            filtered.fold<double>(0, (sum, order) => sum + order.totalPrice);
        return Column(
          key: ValueKey(isMonthly),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IncomeSummaryCard(
              title:
                  isMonthly ? 'Pendapatan Bulan Ini' : 'Pendapatan Minggu Ini',
              amount: 'Rp ${total.toStringAsFixed(0)}',
              labels: const [],
              values: const [],
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _SmallSummaryCard(
                      title: 'Order Selesai',
                      value: '${filtered.length} Pesanan')),
              const SizedBox(width: 8),
              Expanded(
                  child: _SmallSummaryCard(
                      title: 'Rata-rata',
                      value: filtered.isEmpty
                          ? 'Rp 0'
                          : 'Rp ${(total / filtered.length).toStringAsFixed(0)}')),
            ]),
            const SizedBox(height: 22),
            const _SectionHeading('Transaksi Selesai'),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              const Text('Belum ada order selesai pada periode ini',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ...filtered.map((order) => _TransactionCard(
                    time:
                        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                    name: order.customerName ?? 'Customer CleanPick',
                    detail:
                        '${order.wasteType.label} - ${order.vehicleType.label}',
                    income: '+Rp ${order.totalPrice.toStringAsFixed(0)}',
                  )),
          ],
        );
      },
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  const _PeriodButton(
      {required this.label, required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? AppColors.primary : Colors.transparent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ignore: unused_element
class _WeeklyIncomeContent extends StatelessWidget {
  const _WeeklyIncomeContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('weekly'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IncomeSummaryCard(
            title: 'Pendapatan Bulan Ini',
            amount: 'Rp 2.450.000',
            labels: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
            values: [0.35, 0.58, 0.72, 0.25, 0.86, 0.78, 0.32]),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _SmallSummaryCard(
                    title: 'Total Pesanan', value: '47 Pesanan')),
            SizedBox(width: 8),
            Expanded(
                child: _SmallSummaryCard(
                    title: 'Rata-rata / Hari', value: 'Rp 115.000')),
          ],
        ),
        SizedBox(height: 22),
        _SectionHeading('Minggu Ini, 19-25 Feb'),
        SizedBox(height: 10),
        _TransactionCard(
            time: '08:30',
            name: 'Budi Santoso',
            detail: 'Kertas, Plastik - Pickup',
            income: '+Rp 45.000'),
        _TransactionCard(
            time: '11:15',
            name: 'Siti Rahma',
            detail: 'Plastik - Motor',
            income: '+Rp 30.000'),
        _TransactionCard(
            time: '14:00',
            name: 'Hendra Wijaya',
            detail: 'Logam, Kaca - Pickup Box',
            income: '+Rp 60.000'),
      ],
    );
  }
}

// ignore: unused_element
class _MonthlyIncomeContent extends StatelessWidget {
  const _MonthlyIncomeContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('monthly'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IncomeSummaryCard(
            title: 'Pendapatan Bulan Ini (Juni)',
            amount: 'Rp 8.750.000',
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun'],
            values: [0.5, 0.3, 0.78, 0.56, 0.82, 0.98]),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _SmallSummaryCard(
                    title: 'Total Pesanan', value: '142 Pesanan')),
            SizedBox(width: 8),
            Expanded(
                child: _SmallSummaryCard(
                    title: 'Rata-rata / Hari', value: 'Rp 291.000')),
          ],
        ),
        SizedBox(height: 22),
        _SectionHeading('Rincian Harian Terbaru'),
        SizedBox(height: 10),
        _DailyIncomeCard(
            date: 'Selasa, 25 Jun', orders: '6 Pesanan', income: '+Rp 280.000'),
        _DailyIncomeCard(
            date: 'Senin, 24 Jun', orders: '8 Pesanan', income: '+Rp 395.000'),
        _DailyIncomeCard(
            date: 'Minggu, 23 Jun', orders: '5 Pesanan', income: '+Rp 210.000'),
      ],
    );
  }
}

class _IncomeSummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final List<String> labels;
  final List<double> values;
  const _IncomeSummaryCard(
      {required this.title,
      required this.amount,
      required this.labels,
      required this.values});

  @override
  Widget build(BuildContext context) {
    return _CardSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        Text(amount,
            style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 17),
        SizedBox(
          height: 122,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
                labels.length,
                (index) =>
                    _ChartBar(label: labels[index], value: values[index])),
          ),
        ),
      ]),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final double value;
  const _ChartBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: value,
                child: Container(
                  width: 18,
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(label,
              style:
                  const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SmallSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  const _SmallSummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => _CardSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          const SizedBox(height: 7),
          FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary))),
        ]),
      );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary));
}

class _TransactionCard extends StatelessWidget {
  final String time;
  final String name;
  final String detail;
  final String income;
  const _TransactionCard(
      {required this.time,
      required this.name,
      required this.detail,
      required this.income});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _CardSurface(
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6)),
            child: Text(time,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary)),
              ])),
          const SizedBox(width: 5),
          Text(income,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
        ]),
      ),
    );
  }
}

class _DailyIncomeCard extends StatelessWidget {
  final String date;
  final String orders;
  final String income;
  const _DailyIncomeCard(
      {required this.date, required this.orders, required this.income});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _CardSurface(
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(date,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(orders,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ])),
          Text(income,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _CardSurface extends StatelessWidget {
  final Widget child;
  const _CardSurface({required this.child});

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
                color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: child,
      );
}
