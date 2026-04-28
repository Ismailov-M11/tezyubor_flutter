import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String? _selectedStatus;
  final _statuses = [
    null,
    'pending',
    'awaiting_confirmation',
    'confirmed',
    'courier_pickup',
    'delivered',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(adminOrdersProvider.notifier)
                .load(status: _selectedStatus),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final isSelected = _selectedStatus == s;
                return FilterChip(
                  label: Text(
                    s == null ? 'Все' : StatusBadge.labelFor(s),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedStatus = s);
                    ref
                        .read(adminOrdersProvider.notifier)
                        .load(status: _selectedStatus);
                  },
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                );
              },
            ),
          ),
        ),
      ),
      body: state.isLoading && state.orders.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.orders.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(adminOrdersProvider.notifier).load(),
                )
              : state.orders.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long,
                      title: 'Нет заказов',
                      subtitle: 'Заказы появятся после их создания',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(adminOrdersProvider.notifier)
                          .load(status: _selectedStatus),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _AdminOrderCard(order: state.orders[i]),
                      ),
                    ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  final AdminOrder order;

  const _AdminOrderCard({required this.order});

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.token.substring(0, 8).toUpperCase()}',
                        style: theme.textTheme.titleSmall,
                      ),
                      if (order.pharmacy != null)
                        Text(
                          order.pharmacy!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            _row(context, Icons.medication_outlined, 'Сумма',
                '${order.medicinesTotal.toStringAsFixed(0)} сум'),
            if (order.customerPhone != null)
              _row(context, Icons.phone_outlined, 'Телефон',
                  order.customerPhone!),
            if (order.courierType != null)
              _row(context, Icons.local_shipping_outlined, 'Курьер',
                  order.courierType!),
            _row(
              context,
              Icons.access_time,
              'Дата',
              _formatDate(order.createdAt),
            ),
            if (order.status == 'pending' || order.status == 'awaiting_confirmation') ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmOrder(context, ref),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Подтвердить'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteOrder(context, ref),
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
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

  Widget _row(BuildContext ctx, IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('$label: ', style: Theme.of(ctx).textTheme.bodySmall),
            Expanded(
              child: Text(
                value,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(adminOrdersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Заказ подтверждён' : 'Ошибка')),
      );
    }
  }

  Future<void> _deleteOrder(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заказ?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(adminOrdersProvider.notifier).deleteOrder(order.id);
    }
  }
}
