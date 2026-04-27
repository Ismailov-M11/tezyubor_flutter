import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import 'create_order_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final bool openCreate;

  const OrdersScreen({super.key, this.openCreate = false});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  void _openCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateOrderSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading && state.orders.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.orders.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(ordersProvider.notifier).load(),
                )
              : state.orders.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long,
                      title: 'Нет заказов',
                      subtitle: 'Создайте первый заказ',
                      action: ElevatedButton.icon(
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add),
                        label: const Text('Создать заказ'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(ordersProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _OrderCard(order: state.orders[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Новый заказ'),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final PharmacyOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${order.token.substring(0, 8).toUpperCase()}',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.medication_outlined,
              label: 'Лекарства',
              value: '${order.medicinesTotal.toStringAsFixed(0)} сум',
              context: context,
            ),
            if (order.deliveryPrice != null) ...[
              const SizedBox(height: 4),
              _infoRow(
                icon: Icons.delivery_dining,
                label: 'Доставка',
                value: '${order.deliveryPrice!.toStringAsFixed(0)} сум',
                context: context,
              ),
            ],
            if (order.customerName != null || order.customerPhone != null) ...[
              const SizedBox(height: 4),
              _infoRow(
                icon: Icons.person_outline,
                label: 'Клиент',
                value: [order.customerName, order.customerPhone]
                    .where((e) => e != null)
                    .join(' · '),
                context: context,
              ),
            ],
            if (order.courierType != null) ...[
              const SizedBox(height: 4),
              _infoRow(
                icon: Icons.local_shipping_outlined,
                label: 'Курьер',
                value: order.courierType!,
                context: context,
              ),
            ],
            if (order.status == 'pending') ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancel(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 38),
                      ),
                      child: const Text('Отменить'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirm(context, ref),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      child: const Text('Подтвердить'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok =
        await ref.read(ordersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Заказ подтверждён' : 'Ошибка')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отменить заказ?'),
        content:
            const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.token);
    }
  }
}
