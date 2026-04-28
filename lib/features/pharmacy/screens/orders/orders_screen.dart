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

class OrdersScreen extends ConsumerStatefulWidget {
  final bool openCreate;
  const OrdersScreen({super.key, this.openCreate = false});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.openCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  @override
  void dispose() {
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
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final f = ref.read(ordersProvider).filter.copyWith(
            search: value,
            clearSearch: value.isEmpty,
          );
      ref.read(ordersProvider.notifier).applyFilter(f);
    });
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

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.search,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              )
            : Text(l10n.orders),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _searchVisible = !_searchVisible);
              if (!_searchVisible) {
                _searchController.clear();
                final f = ref
                    .read(ordersProvider)
                    .filter
                    .copyWith(clearSearch: true);
                ref.read(ordersProvider.notifier).applyFilter(f);
              }
            },
          ),
          Badge(
            isLabelVisible: hasFilter,
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _openFilter,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.filter.statuses.isNotEmpty ||
              state.filter.dateFrom != null ||
              state.filter.dateTo != null)
            _ActiveFilterRow(
              filter: state.filter,
              onClear: () => ref.read(ordersProvider.notifier).clearFilter(),
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
                    : state.orders.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long,
                            title: l10n.noOrders,
                            subtitle: hasFilter
                                ? l10n.clear
                                : l10n.createFirstOrder,
                            action: hasFilter
                                ? OutlinedButton(
                                    onPressed: () => ref
                                        .read(ordersProvider.notifier)
                                        .clearFilter(),
                                    child: Text(l10n.clear),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _openCreate,
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.createOrder),
                                  ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(ordersProvider.notifier).load(),
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.orders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _OrderCard(
                                order: state.orders[i],
                                onTap: () => _showDetail(state.orders[i]),
                              ),
                            ),
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
                ...filter.statuses.map((s) => Chip(
                      label: Text(StatusBadge.labelFor(s),
                          style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          StatusBadge.colorFor(s).withValues(alpha: 0.15),
                    )),
                if (filter.dateFrom != null || filter.dateTo != null)
                  Chip(
                    label: Text(
                      [
                        if (filter.dateFrom != null)
                          '${l10n.from} ${_fmt(filter.dateFrom!)}',
                        if (filter.dateTo != null)
                          '${l10n.to} ${_fmt(filter.dateTo!)}',
                      ].join(' '),
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
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

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
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

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${order.token.length >= 8 ? order.token.substring(0, 8).toUpperCase() : order.token.toUpperCase()}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 10),
              _row(Icons.medication_outlined, l10n.medicines,
                  '${order.medicinesTotal.toStringAsFixed(0)} сум', context),
              if (order.deliveryPrice != null) ...[
                const SizedBox(height: 4),
                _row(Icons.delivery_dining, l10n.deliveryCost,
                    '${order.deliveryPrice!.toStringAsFixed(0)} сум', context),
              ],
              if (order.customerName != null || order.customerPhone != null) ...[
                const SizedBox(height: 4),
                _row(
                  Icons.person_outline,
                  l10n.customer,
                  [order.customerName, order.customerPhone]
                      .where((e) => e != null)
                      .join(' · '),
                  context,
                ),
              ],
              if (order.courierType != null) ...[
                const SizedBox(height: 4),
                _row(Icons.local_shipping_outlined, l10n.courier,
                    order.courierType!, context),
              ],
              // Actions based on status
              if (order.status == 'pending' ||
                  order.status == 'awaiting_confirmation') ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
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
                    if (order.status == 'awaiting_confirmation') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _confirm(context, ref),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(l10n.confirm),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, BuildContext ctx) =>
      Row(
        children: [
          Icon(icon,
              size: 15,
              color: Theme.of(ctx).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text('$label: ',
              style: Theme.of(ctx).textTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok =
        await ref.read(ordersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                ok ? context.l10n.orderConfirmed : context.l10n.error)),
      );
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
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.token);
    }
  }
}

// ─── Order detail sheet ───────────────────────────────────────────────────────

class _OrderDetailSheet extends ConsumerWidget {
  final PharmacyOrder order;
  const _OrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final total = order.medicinesTotal + (order.deliveryPrice ?? 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${l10n.orderDetail} #${order.token.length >= 8 ? order.token.substring(0, 8).toUpperCase() : order.token.toUpperCase()}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              children: [
                // Status
                _StatusBar(status: order.status),
                const SizedBox(height: 20),

                // Financial summary
                _SectionCard(children: [
                  _DetailRow(
                      icon: Icons.medication_outlined,
                      label: l10n.medicines,
                      value:
                          '${order.medicinesTotal.toStringAsFixed(0)} сум'),
                  if (order.deliveryPrice != null)
                    _DetailRow(
                        icon: Icons.delivery_dining,
                        label: l10n.deliveryCost,
                        value:
                            '${order.deliveryPrice!.toStringAsFixed(0)} сум'),
                  _DetailRow(
                    icon: Icons.receipt_outlined,
                    label: l10n.totalCost,
                    value: '${total.toStringAsFixed(0)} сум',
                    bold: true,
                  ),
                ]),
                const SizedBox(height: 12),

                // Customer info
                if (order.customerName != null ||
                    order.customerPhone != null ||
                    order.customerAddress != null) ...[
                  _SectionTitle(l10n.customer),
                  _SectionCard(children: [
                    if (order.customerName != null)
                      _DetailRow(
                          icon: Icons.person_outline,
                          label: l10n.customer,
                          value: order.customerName!),
                    if (order.customerPhone != null)
                      _DetailRow(
                          icon: Icons.phone_outlined,
                          label: l10n.phone,
                          value: order.customerPhone!),
                    if (order.customerAddress != null)
                      _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: l10n.address,
                          value: order.customerAddress!),
                  ]),
                  const SizedBox(height: 12),
                ],

                // Courier & tracking
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

                // Dates
                _SectionCard(children: [
                  _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.createdAt,
                      value: _fmtDate(order.createdAt)),
                ]),
                const SizedBox(height: 20),

                // Action buttons
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

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusBar extends StatelessWidget {
  final String status;
  const _StatusBar({required this.status});

  static const _steps = [
    'pending',
    'awaiting_confirmation',
    'confirmed',
    'courier_pickup',
    'courier_picked',
    'courier_delivery',
    'delivered',
  ];

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Center(
        child: StatusBadge(status: status),
      );
    }
    final currentIdx = _steps.indexOf(status);
    final color = StatusBadge.colorFor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: StatusBadge(status: status)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final stepIdx = i ~/ 2;
              return Expanded(
                child: Container(
                  height: 3,
                  color: stepIdx < currentIdx
                      ? color
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                ),
              );
            }
            final stepIdx = i ~/ 2;
            final done = stepIdx <= currentIdx;
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: done
                    ? color
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TrackingRow extends StatelessWidget {
  final String url;
  final AppL10n l10n;
  const _TrackingRow({required this.url, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.link, size: 18,
              color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.trackingLink,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(url);
              if (uri != null) await launchUrl(uri);
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
                SnackBar(content: Text(l10n.copied)),
              );
            },
            tooltip: l10n.copyLink,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final PharmacyOrder order;
  final WidgetRef ref;
  final AppL10n l10n;
  const _ActionButtons(
      {required this.order, required this.ref, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  minimumSize: const Size(0, 44)),
              child: Text(l10n.confirm),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok =
        await ref.read(ordersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok ? l10n.orderConfirmed : l10n.error)),
      );
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
              child: Text(l10n.cancel)),
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
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ─── Order filter sheet ───────────────────────────────────────────────────────

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
  late List<String> _statuses;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const _allStatuses = [
    'pending',
    'awaiting_confirmation',
    'confirmed',
    'courier_pickup',
    'courier_picked',
    'courier_delivery',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _statuses = List.from(widget.current.statuses);
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
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text(l10n.filter,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 8),

          // Status chips
          Text(l10n.statusFilter,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _allStatuses.map((s) {
              final sel = _statuses.contains(s);
              final color = StatusBadge.colorFor(s);
              return FilterChip(
                label: Text(StatusBadge.labelFor(s),
                    style: TextStyle(
                        fontSize: 12,
                        color: sel ? Colors.white : color)),
                selected: sel,
                selectedColor: color,
                checkmarkColor: Colors.white,
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                onSelected: (v) => setState(() {
                  if (v) {
                    _statuses.add(s);
                  } else {
                    _statuses.remove(s);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Date range
          Text(l10n.dateRange,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dateFrom != null
                        ? _fmt(_dateFrom!)
                        : l10n.from,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dateTo != null ? _fmt(_dateTo!) : l10n.to,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () => _pickDate(false),
                ),
              ),
              if (_dateFrom != null || _dateTo != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () =>
                      setState(() { _dateFrom = null; _dateTo = null; }),
                ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(OrdersFilter(
                  statuses: _statuses,
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                ));
                Navigator.pop(context);
              },
              child: Text(l10n.apply),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4)),
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

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: AppColors.primary),
            const SizedBox(width: 10),
            Text('$label: ',
                style: Theme.of(context).textTheme.bodySmall),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          bold ? FontWeight.bold : FontWeight.w500,
                    ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
}
