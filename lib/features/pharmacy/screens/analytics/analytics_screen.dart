import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final data = state.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(analyticsProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading && data == null
          ? const CenteredLoader()
          : state.error != null && data == null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(analyticsProvider.notifier).load(),
                )
              : data == null
                  ? const SizedBox()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(analyticsProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // KPI cards
                          _MetricsGrid(data: data),
                          const SizedBox(height: 20),

                          // Orders by day chart
                          if (data.ordersByDay.isNotEmpty) ...[
                            _SectionHeader(title: 'Заказы по дням'),
                            const SizedBox(height: 12),
                            _DailyOrdersChart(days: data.ordersByDay),
                            const SizedBox(height: 20),
                          ],

                          // Orders by status
                          if (data.ordersByStatus.isNotEmpty) ...[
                            _SectionHeader(title: 'По статусам'),
                            const SizedBox(height: 12),
                            _StatusBreakdown(statusMap: data.ordersByStatus),
                            const SizedBox(height: 20),
                          ],

                          // Orders by courier
                          if (data.ordersByCourier.isNotEmpty) ...[
                            _SectionHeader(title: 'По курьерам'),
                            const SizedBox(height: 12),
                            _CourierBreakdown(courierMap: data.ordersByCourier),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final dynamic data;

  const _MetricsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem(
        label: 'Всего заказов',
        value: data.totalOrders.toString(),
        icon: Icons.receipt_long,
        color: AppColors.primary,
      ),
      _MetricItem(
        label: 'Сумма лекарств',
        value: _fmt(data.totalMedicines),
        icon: Icons.medication,
        color: AppColors.info,
      ),
      _MetricItem(
        label: 'Доставка',
        value: _fmt(data.totalDelivery),
        icon: Icons.delivery_dining,
        color: AppColors.success,
      ),
      _MetricItem(
        label: 'Общая выручка',
        value: _fmt(data.totalRevenue),
        icon: Icons.attach_money,
        color: AppColors.warning,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items.map((item) => _MetricCard(item: item)).toList(),
    );
  }

  String _fmt(double v) =>
      v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M' : '${v.toStringAsFixed(0)} сум';
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricItem item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 18, color: item.color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(item.label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall);
  }
}

class _DailyOrdersChart extends StatelessWidget {
  final List<dynamic> days;

  const _DailyOrdersChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final last14 = days.length > 14 ? days.sublist(days.length - 14) : days;
    final maxY = last14.fold<int>(0, (m, d) => m > (d.count as int) ? m : (d.count as int)).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: (maxY * 1.2).ceilToDouble(),
              barGroups: last14.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: (e.value.count as int).toDouble(),
                      color: AppColors.primary,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= last14.length) return const SizedBox();
                      final date = (last14[idx].date as String).substring(5);
                      return Text(date, style: const TextStyle(fontSize: 9));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  strokeWidth: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> statusMap;

  const _StatusBreakdown({required this.statusMap});

  @override
  Widget build(BuildContext context) {
    final total = statusMap.values.fold(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: statusMap.entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(_statusLabel(e.key),
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor:
                          Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      valueColor:
                          AlwaysStoppedAnimation(_statusColor(e.key)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'pending' => 'Ожидает',
        'awaiting_confirmation' => 'Ожид. подтв.',
        'confirmed' => 'Подтверждён',
        'delivered' => 'Доставлен',
        'cancelled' => 'Отменён',
        _ => s,
      };

  Color _statusColor(String s) => switch (s) {
        'pending' => AppColors.statusPending,
        'awaiting_confirmation' => AppColors.statusAwaiting,
        'confirmed' => AppColors.statusConfirmed,
        'delivered' => AppColors.statusDelivered,
        'cancelled' => AppColors.statusCancelled,
        _ => AppColors.primary,
      };
}

class _CourierBreakdown extends StatelessWidget {
  final Map<String, int> courierMap;

  const _CourierBreakdown({required this.courierMap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: courierMap.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(e.key, style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(
                    '${e.value} заказов',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
