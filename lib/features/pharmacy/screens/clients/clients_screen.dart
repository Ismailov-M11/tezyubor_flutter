import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../models/client_model.dart';
import '../../providers/clients_provider.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final f = ref.read(clientsProvider).filter.copyWith(
            search: value,
            clearSearch: value.isEmpty,
          );
      ref.read(clientsProvider.notifier).applyFilter(f);
    });
  }

  void _openFilter() {
    final current = ref.read(clientsProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ClientFilterSheet(
        current: current,
        onApply: (f) => ref.read(clientsProvider.notifier).applyFilter(f),
        onClear: () => ref.read(clientsProvider.notifier).clearFilter(),
      ),
    );
  }

  void _showDetail(PharmacyClient client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ClientDetailSheet(client: client),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(clientsProvider);
    final hasFilter = state.filter.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clients),
        actions: [
          Badge(
            isLabelVisible: hasFilter &&
                (state.filter.dateFrom != null ||
                    state.filter.dateTo != null ||
                    state.filter.minOrders != null),
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _openFilter,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(clientsProvider.notifier).load(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchByPhone,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          final f = ref
                              .read(clientsProvider)
                              .filter
                              .copyWith(clearSearch: true);
                          ref
                              .read(clientsProvider.notifier)
                              .applyFilter(f);
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) {
                setState(() {});
                _onSearch(v);
              },
            ),
          ),
        ),
      ),
      body: state.isLoading && state.clients.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.clients.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(clientsProvider.notifier).load(),
                )
              : state.clients.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: l10n.noClients,
                      subtitle: hasFilter
                          ? l10n.clear
                          : l10n.clientsSubtitle,
                      action: hasFilter
                          ? OutlinedButton(
                              onPressed: () => ref
                                  .read(clientsProvider.notifier)
                                  .clearFilter(),
                              child: Text(l10n.clear),
                            )
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(clientsProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.clients.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = state.clients[i];
                          return _ClientCard(
                            client: c,
                            onTap: () => _showDetail(c),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ─── Client card ──────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final PharmacyClient client;
  final VoidCallback onTap;

  const _ClientCard({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = client;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              c.name?.isNotEmpty == true
                  ? c.name![0].toUpperCase()
                  : c.phone[0],
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            c.name ?? c.phone,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.name != null)
                Text(c.phone,
                    style: Theme.of(context).textTheme.bodySmall),
              if (c.lastAddress != null)
                Text(
                  c.lastAddress!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${c.ordersCount}',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.primary),
              ),
              Text(l10n.ordersCount,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          isThreeLine: c.lastAddress != null,
        ),
      ),
    );
  }
}

// ─── Client detail sheet ──────────────────────────────────────────────────────

class _ClientDetailSheet extends StatelessWidget {
  final PharmacyClient client;
  const _ClientDetailSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Text(l10n.clientDetails,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Avatar + name
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              client.name?.isNotEmpty == true
                  ? client.name![0].toUpperCase()
                  : client.phone[0],
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          if (client.name != null)
            Text(client.name!,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          Text(client.phone,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                  icon: Icons.receipt_long,
                  value: '${client.ordersCount}',
                  label: l10n.ordersCount),
              if (client.lastOrderAt != null)
                _StatChip(
                    icon: Icons.access_time,
                    value: _fmtDate(client.lastOrderAt!),
                    label: l10n.lastOrder),
            ],
          ),
          const SizedBox(height: 16),

          // Last address
          if (client.lastAddress != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.address,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(client.lastAddress!,
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

// ─── Client filter sheet ──────────────────────────────────────────────────────

class _ClientFilterSheet extends StatefulWidget {
  final ClientsFilter current;
  final void Function(ClientsFilter) onApply;
  final VoidCallback onClear;

  const _ClientFilterSheet({
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_ClientFilterSheet> createState() => _ClientFilterSheetState();
}

class _ClientFilterSheetState extends State<_ClientFilterSheet> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _minOrders;
  final _minOrdersCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.current.dateFrom;
    _dateTo = widget.current.dateTo;
    _minOrders = widget.current.minOrders;
    if (_minOrders != null) _minOrdersCtrl.text = '$_minOrders';
  }

  @override
  void dispose() {
    _minOrdersCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => isFrom ? _dateFrom = picked : _dateTo = picked);
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
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () { widget.onClear(); Navigator.pop(context); },
                child: Text(l10n.clear),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date range
          Text(l10n.dateRange,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateFrom != null ? _fmt(_dateFrom!) : l10n.from,
                      style: const TextStyle(fontSize: 13)),
                  onPressed: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateTo != null ? _fmt(_dateTo!) : l10n.to,
                      style: const TextStyle(fontSize: 13)),
                  onPressed: () => _pickDate(false),
                ),
              ),
              if (_dateFrom != null || _dateTo != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() { _dateFrom = null; _dateTo = null; }),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Min orders
          Text(l10n.minOrders,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _minOrdersCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              isDense: true,
              suffixIcon: _minOrdersCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _minOrdersCtrl.clear();
                        setState(() => _minOrders = null);
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(
                () => _minOrders = int.tryParse(v)),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(ClientsFilter(
                  search: widget.current.search,
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                  minOrders: _minOrders,
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
