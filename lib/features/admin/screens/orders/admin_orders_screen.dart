import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';

const _adminStatusOrder = [
  'pending',
  'awaiting_confirmation',
  'confirmed',
  'courier_pickup',
  'courier_picked',
  'courier_delivery',
  'delivered',
  'cancelled',
];

const _allCouriers = ['yandex', 'noor', 'millennium'];

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String? _selectedCourier;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const _tabStatuses = ['all', ..._adminStatusOrder];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabStatuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _tabLabel(String status, AppL10n l10n) {
    if (status == 'all') return l10n.adminStatusAll;
    return StatusBadge.labelFor(status);
  }

  void _applyFilter() {
    final filter = AdminOrdersFilter(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      courier: _selectedCourier,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
    ref.read(adminOrdersProvider.notifier).applyFilter(filter);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCourier = null;
      _dateFrom = null;
      _dateTo = null;
    });
    ref.read(adminOrdersProvider.notifier).clearFilter();
  }

  Future<void> _pickDate(BuildContext ctx, bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(adminOrdersProvider);
    final isFiltered = state.filter.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminOrdersTitle),
        actions: [
          if (isFiltered)
            TextButton(
              onPressed: _clearFilters,
              child: Text(l10n.clear,
                  style: const TextStyle(color: AppColors.primary)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.adminSearchOrders,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              _applyFilter();
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    setState(() {});
                    if (v.length >= 3 || v.isEmpty) _applyFilter();
                  },
                ),
              ),
              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      icon: Icons.local_shipping_outlined,
                      label: _selectedCourier ?? l10n.adminCourierAll,
                      isActive: _selectedCourier != null,
                      onTap: () => _showCourierSheet(context, l10n),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.calendar_today_outlined,
                      label: _dateFrom != null
                          ? '${_dateFrom!.day}.${_dateFrom!.month}.${_dateFrom!.year}'
                          : l10n.from,
                      isActive: _dateFrom != null,
                      onTap: () => _pickDate(context, true),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.calendar_today_outlined,
                      label: _dateTo != null
                          ? '${_dateTo!.day}.${_dateTo!.month}.${_dateTo!.year}'
                          : l10n.to,
                      isActive: _dateTo != null,
                      onTap: () => _pickDate(context, false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Tab bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                indicatorWeight: 2.5,
                tabs: _tabStatuses
                    .map((s) => Tab(text: _tabLabel(s, l10n)))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      body: state.isLoading && state.orders.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.orders.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminOrdersProvider.notifier).load(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _tabStatuses.map((status) {
                    final orders = status == 'all'
                        ? state.orders
                        : state.orders
                            .where((o) => o.status == status)
                            .toList();
                    return _AdminTabOrderList(
                      key: ValueKey(status),
                      orders: orders,
                      l10n: l10n,
                    );
                  }).toList(),
                ),
    );
  }

  void _showCourierSheet(BuildContext context, AppL10n l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(l10n.adminCourierAll),
              leading: const Icon(Icons.all_inclusive),
              selected: _selectedCourier == null,
              selectedColor: AppColors.primary,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedCourier = null);
                _applyFilter();
              },
            ),
            ..._allCouriers.map((courier) => ListTile(
                  title: Text(courier.toUpperCase()),
                  leading: const Icon(Icons.local_shipping_outlined),
                  selected: _selectedCourier == courier,
                  selectedColor: AppColors.primary,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedCourier = courier);
                    _applyFilter();
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab list ─────────────────────────────────────────────────────────────────

class _AdminTabOrderList extends ConsumerWidget {
  final List<AdminOrder> orders;
  final AppL10n l10n;

  const _AdminTabOrderList({super.key, required this.orders, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        title: l10n.adminNoOrders,
        subtitle: l10n.adminNoOrdersSub,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminOrdersProvider.notifier).load(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _AdminOrderCard(order: orders[i], l10n: l10n),
      ),
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _AdminOrderCard extends ConsumerWidget {
  final AdminOrder order;
  final AppL10n l10n;

  const _AdminOrderCard({required this.order, required this.l10n});

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
                        '#${order.token.toUpperCase()}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (order.pharmacyName != null)
                        Text(
                          order.pharmacyName!,
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
            _row(context, Icons.shopping_bag_outlined, l10n.adminOrderSum,
                '${order.medicinesTotal.toStringAsFixed(0)} сум'),
            if (order.customerPhone != null)
              _row(context, Icons.phone_outlined, l10n.phone,
                  order.customerPhone!),
            if (order.customerAddress != null)
              _row(context, Icons.location_on_outlined, l10n.address,
                  order.customerAddress!),
            if (order.selectedCourier != null)
              _row(context, Icons.local_shipping_outlined,
                  l10n.adminOrderCourier, order.selectedCourier!.toUpperCase()),
            _row(
              context,
              Icons.access_time,
              l10n.adminOrderDate,
              _formatDate(order.createdAt),
            ),
            if (order.status == 'pending' ||
                order.status == 'awaiting_confirmation') ...[
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
                      child: Text(l10n.adminConfirmOrder),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteOrder(context, ref),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.error.withValues(alpha: 0.1),
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
            Icon(icon,
                size: 14,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant),
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
    final ok =
        await ref.read(adminOrdersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok
                ? context.l10n.adminOrderConfirmed
                : context.l10n.adminOrderError)),
      );
    }
  }

  Future<void> _deleteOrder(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteOrder),
        content: Text(l10n.adminDeleteOrderMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(adminOrdersProvider.notifier).deleteOrder(order.id);
    }
  }
}
