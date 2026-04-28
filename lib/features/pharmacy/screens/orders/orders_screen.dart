import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import 'create_order_screen.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtAmount(double? v) {
  if (v == null) return '—';
  final str = v.toStringAsFixed(0);
  final buf = StringBuffer();
  final len = str.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(' ');
    buf.write(str[i]);
  }
  return '${buf.toString()} сум';
}

String _fmtDate(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

String _fmtDateShort(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

const _statusOrder = [
  'pending',
  'awaiting_confirmation',
  'confirmed',
  'courier_pickup',
  'courier_picked',
  'courier_delivery',
  'delivered',
  'cancelled',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerStatefulWidget {
  final bool openCreate;
  const OrdersScreen({super.key, this.openCreate = false});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _searchVisible = false;

  static const _tabStatuses = ['all', ..._statusOrder];

  String _tabLabel(String status, AppL10n l10n) {
    if (status == 'all') return l10n.all;
    return StatusBadge.labelFor(status);
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _tabStatuses.length, vsync: this);
    if (widget.openCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final f = ref.read(ordersProvider).filter.copyWith(
            search: value,
            clearSearch: value.isEmpty,
          );
      ref.read(ordersProvider.notifier).applyFilter(f);
    });
  }

  void _toggleSearch() {
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _searchController.clear();
      final f =
          ref.read(ordersProvider).filter.copyWith(clearSearch: true);
      ref.read(ordersProvider.notifier).applyFilter(f);
    }
  }

  void _openFilter() {
    final current = ref.read(ordersProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _OrderFilterSheet(
        current: current,
        onApply: (f) => ref.read(ordersProvider.notifier).applyFilter(f),
        onClear: () => ref.read(ordersProvider.notifier).clearFilter(),
      ),
    );
  }

  void _showDetail(PharmacyOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(ordersProvider);
    final hasFilter = state.filter.isActive;
    final hasCourierDateFilter = state.filter.couriers.isNotEmpty ||
        state.filter.dateFrom != null ||
        state.filter.dateTo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orders),
        actions: [
          IconButton(
            icon: Icon(
                _searchVisible ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          Badge(
            isLabelVisible: hasFilter,
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.tune_outlined),
              onPressed: _openFilter,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searchVisible ? 100 : 48),
          child: Column(
            children: [
              if (_searchVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                ref
                                    .read(ordersProvider.notifier)
                                    .applyFilter(ref
                                        .read(ordersProvider)
                                        .filter
                                        .copyWith(clearSearch: true));
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      setState(() {});
                      _onSearchChanged(v);
                    },
                  ),
                ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13),
                indicatorWeight: 2.5,
                tabs: _tabStatuses
                    .map((s) => Tab(text: _tabLabel(s, l10n)))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (hasCourierDateFilter)
            _ActiveFilterRow(
              filter: state.filter,
              onClear: () =>
                  ref.read(ordersProvider.notifier).clearFilter(),
            ),
          Expanded(
            child: state.isLoading && state.orders.isEmpty
                ? const CenteredLoader()
                : state.error != null && state.orders.isEmpty
                    ? AppErrorWidget(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(ordersProvider.notifier).load(),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: _tabStatuses.map((status) {
                          final orders = status == 'all'
                              ? state.orders
                              : state.orders
                                  .where((o) => o.status == status)
                                  .toList();
                          return _TabOrderList(
                            key: ValueKey(status),
                            orders: orders,
                            hasFilter: hasFilter,
                            onClearFilter: () => ref
                                .read(ordersProvider.notifier)
                                .clearFilter(),
                            onOpenCreate: _openCreate,
                            onShowDetail: _showDetail,
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.newOrder),
      ),
    );
  }
}

// ─── Tab order list ───────────────────────────────────────────────────────────

class _TabOrderList extends ConsumerWidget {
  final List<PharmacyOrder> orders;
  final bool hasFilter;
  final VoidCallback onClearFilter;
  final VoidCallback onOpenCreate;
  final void Function(PharmacyOrder) onShowDetail;

  const _TabOrderList({
    super.key,
    required this.orders,
    required this.hasFilter,
    required this.onClearFilter,
    required this.onOpenCreate,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        title: l10n.noOrders,
        subtitle: hasFilter ? l10n.clear : l10n.createFirstOrder,
        action: hasFilter
            ? OutlinedButton(
                onPressed: onClearFilter,
                child: Text(l10n.clear),
              )
            : ElevatedButton.icon(
                onPressed: onOpenCreate,
                icon: const Icon(Icons.add),
                label: Text(l10n.createOrder),
              ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).load(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          onTap: () => onShowDetail(orders[i]),
        ),
      ),
    );
  }
}

// ─── Active filter chips row ──────────────────────────────────────────────────

class _ActiveFilterRow extends StatelessWidget {
  final OrdersFilter filter;
  final VoidCallback onClear;
  const _ActiveFilterRow({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...filter.couriers.map((c) => _FilterChip(
                      label: c[0].toUpperCase() + c.substring(1),
                      color: AppColors.primary,
                    )),
                if (filter.dateFrom != null || filter.dateTo != null)
                  _FilterChip(
                    label: [
                      if (filter.dateFrom != null)
                        '${l10n.from} ${_fmtShort(filter.dateFrom!)}',
                      if (filter.dateTo != null)
                        '${l10n.to} ${_fmtShort(filter.dateTo!)}',
                    ].join(' '),
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            tooltip: l10n.clear,
          ),
        ],
      ),
    );
  }

  String _fmtShort(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FilterChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600)),
      );
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends ConsumerWidget {
  final PharmacyOrder order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final total = order.totalPrice ??
        ((order.medicinesTotal ?? 0.0) + (order.deliveryPrice ?? 0.0));

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Token + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.token.toUpperCase()}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: order.status),
                ],
              ),

              // Comment preview
              if (order.pharmacyComment != null &&
                  order.pharmacyComment!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  order.pharmacyComment!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Customer
              if (order.customerName != null ||
                  order.customerPhone != null) ...[
                const SizedBox(height: 5),
                _CardRow(
                  icon: Icons.person_outline,
                  value: [order.customerName, order.customerPhone]
                      .where((e) => e != null)
                      .join(' · '),
                ),
              ],

              // Customer address
              if (order.customerAddress != null) ...[
                const SizedBox(height: 3),
                _CardRow(
                  icon: Icons.location_on_outlined,
                  value: order.customerAddress!,
                  truncate: true,
                ),
              ],

              // Courier
              if (order.courierType != null) ...[
                const SizedBox(height: 3),
                _CardRow(
                  icon: Icons.local_shipping_outlined,
                  value: order.courierType!,
                ),
              ],

              // Bottom: date | total
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDateShort(order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (total > 0)
                    Text(
                      _fmtAmount(total),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),

              // Actions — awaiting_confirmation only
              if (order.status == 'awaiting_confirmation') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancel(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _confirm(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(l10n.confirm),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok =
        await ref.read(ordersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              ok ? context.l10n.orderConfirmed : context.l10n.error)));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrderTitle),
        content: Text(l10n.cancelOrderMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.no)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.token);
    }
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool truncate;
  const _CardRow(
      {required this.icon, required this.value, this.truncate = false});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon,
              size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: truncate ? 1 : null,
              overflow: truncate ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      );
}

// ─── Order detail sheet ───────────────────────────────────────────────────────

class _OrderDetailSheet extends ConsumerWidget {
  final PharmacyOrder order;
  const _OrderDetailSheet({required this.order});

  bool get _canShare =>
      order.status != 'cancelled' && order.status != 'delivered';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final total = order.totalPrice ??
        ((order.medicinesTotal ?? 0.0) + (order.deliveryPrice ?? 0.0));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.token.toUpperCase()}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              children: [
                if (_canShare && order.orderUrl != null) ...[
                  _ShareLinkCard(url: order.orderUrl!, l10n: l10n),
                  const SizedBox(height: 12),
                ],

                if (order.pharmacyComment != null &&
                    order.pharmacyComment!.isNotEmpty) ...[
                  _SectionTitle(l10n.orderCommentLbl),
                  _SectionCard(children: [
                    _DetailRow(
                      icon: Icons.comment_outlined,
                      label: l10n.orderCommentLbl,
                      value: order.pharmacyComment!,
                    ),
                  ]),
                  const SizedBox(height: 12),
                ],

                if (order.customerName != null ||
                    order.customerPhone != null ||
                    order.customerAddress != null ||
                    order.customerComment != null) ...[
                  _SectionTitle(l10n.customer),
                  _SectionCard(children: [
                    if (order.customerName != null)
                      _DetailRow(
                          icon: Icons.person_outline,
                          label: l10n.customer,
                          value: order.customerName!),
                    if (order.customerPhone != null)
                      _PhoneRow(
                          phone: order.customerPhone!, l10n: l10n),
                    if (order.customerAddress != null)
                      _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: l10n.address,
                          value: order.customerAddress!),
                    if (order.customerComment != null &&
                        order.customerComment!.isNotEmpty)
                      _DetailRow(
                          icon: Icons.chat_bubble_outline,
                          label: l10n.customerCommentLbl,
                          value: order.customerComment!),
                  ]),
                  const SizedBox(height: 12),
                ],

                if (order.medicinesTotal != null ||
                    order.deliveryPrice != null) ...[
                  _SectionTitle(l10n.totalCost),
                  _SectionCard(children: [
                    if (order.medicinesTotal != null)
                      _DetailRow(
                          icon: Icons.shopping_bag_outlined,
                          label: l10n.orderAmountLbl,
                          value: _fmtAmount(order.medicinesTotal)),
                    if (order.deliveryPrice != null)
                      _DetailRow(
                          icon: Icons.delivery_dining,
                          label: l10n.deliveryCost,
                          value: _fmtAmount(order.deliveryPrice)),
                    if (total > 0)
                      _DetailRow(
                        icon: Icons.receipt_outlined,
                        label: l10n.totalAmountLbl,
                        value: _fmtAmount(total),
                        bold: true,
                        valueColor: AppColors.primary,
                      ),
                  ]),
                  const SizedBox(height: 12),
                ],

                if (order.courierType != null) ...[
                  _SectionTitle(l10n.courier),
                  _SectionCard(children: [
                    _DetailRow(
                        icon: Icons.local_shipping_outlined,
                        label: l10n.courier,
                        value: order.courierType!),
                    if (order.trackingUrl != null)
                      _TrackingRow(
                          url: order.trackingUrl!, l10n: l10n),
                  ]),
                  const SizedBox(height: 12),
                ],

                if (order.status == 'pending' ||
                    order.status == 'awaiting_confirmation')
                  _ActionButtons(order: order, ref: ref, l10n: l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter sheet (courier + date only) ──────────────────────────────────────

class _OrderFilterSheet extends StatefulWidget {
  final OrdersFilter current;
  final void Function(OrdersFilter) onApply;
  final VoidCallback onClear;

  const _OrderFilterSheet({
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<_OrderFilterSheet> {
  late List<String> _couriers;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  bool _courierExpanded = true;
  bool _dateExpanded = false;

  static const _allCouriers = ['yandex', 'noor', 'millennium'];

  @override
  void initState() {
    super.initState();
    _couriers = List.from(widget.current.couriers);
    _dateFrom = widget.current.dateFrom;
    _dateTo = widget.current.dateTo;
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => isFrom ? _dateFrom = picked : _dateTo = picked);
    }
  }

  int get _activeFilterCount =>
      _couriers.length +
      (_dateFrom != null ? 1 : 0) +
      (_dateTo != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(l10n.filter,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (_activeFilterCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$_activeFilterCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: Text(l10n.clear),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                _FilterSection(
                  title: l10n.courier,
                  count: _couriers.length,
                  expanded: _courierExpanded,
                  onToggle: () =>
                      setState(() => _courierExpanded = !_courierExpanded),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allCouriers.map((c) {
                      final sel = _couriers.contains(c);
                      return _ToggleChip(
                        label: c[0].toUpperCase() + c.substring(1),
                        selected: sel,
                        color: AppColors.primary,
                        onTap: () => setState(() =>
                            sel ? _couriers.remove(c) : _couriers.add(c)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                _FilterSection(
                  title: l10n.dateRange,
                  count: (_dateFrom != null ? 1 : 0) +
                      (_dateTo != null ? 1 : 0),
                  expanded: _dateExpanded,
                  onToggle: () =>
                      setState(() => _dateExpanded = !_dateExpanded),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today,
                              size: 15),
                          label: Text(
                            _dateFrom != null ? _fmt(_dateFrom!) : l10n.from,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today,
                              size: 15),
                          label: Text(
                            _dateTo != null ? _fmt(_dateTo!) : l10n.to,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () => _pickDate(false),
                        ),
                      ),
                      if (_dateFrom != null || _dateTo != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(
                              () { _dateFrom = null; _dateTo = null; }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(OrdersFilter(
                    search: widget.current.search,
                    statuses: widget.current.statuses,
                    couriers: _couriers,
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                  ));
                  Navigator.pop(context);
                },
                child: Text(l10n.apply),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _FilterSection extends StatelessWidget {
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(title.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      );
}

// ─── Share link card ──────────────────────────────────────────────────────────

class _ShareLinkCard extends StatelessWidget {
  final String url;
  final AppL10n l10n;
  const _ShareLinkCard({required this.url, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.shareOrderLink,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
                Text(url,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy,
                size: 18, color: AppColors.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.copied)));
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new,
                size: 18, color: AppColors.primary),
            onPressed: () async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.inAppWebView);
              }
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

// ─── Phone row ────────────────────────────────────────────────────────────────

class _PhoneRow extends StatelessWidget {
  final String phone;
  final AppL10n l10n;
  const _PhoneRow({required this.phone, required this.l10n});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.phone_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('${l10n.phone}: ',
                style: Theme.of(context).textTheme.bodySmall),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final uri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: Text(
                  phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                  textAlign: TextAlign.end,
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── Tracking row ─────────────────────────────────────────────────────────────

class _TrackingRow extends StatelessWidget {
  final String url;
  final AppL10n l10n;
  const _TrackingRow({required this.url, required this.l10n});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.link, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(l10n.trackingLink,
                    style: Theme.of(context).textTheme.bodySmall)),
            TextButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.inAppWebView);
                }
              },
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(l10n.openLink,
                  style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copied)));
              },
            ),
          ],
        ),
      );
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final PharmacyOrder order;
  final WidgetRef ref;
  final AppL10n l10n;
  const _ActionButtons(
      {required this.order, required this.ref, required this.l10n});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _cancel(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(0, 44),
              ),
              child: Text(l10n.cancel),
            ),
          ),
          if (order.status == 'awaiting_confirmation') ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                ),
                child: Text(l10n.confirm),
              ),
            ),
          ],
        ],
      );

  Future<void> _confirm(BuildContext context) async {
    final ok =
        await ref.read(ordersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? l10n.orderConfirmed : l10n.error)));
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrderTitle),
        content: Text(l10n.cancelOrderMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.no)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.token);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('$label: ',
                style: Theme.of(context).textTheme.bodySmall),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          bold ? FontWeight.bold : FontWeight.w500,
                      color: valueColor,
                    ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
}
