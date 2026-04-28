import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../providers/admin_provider.dart';

class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() =>
      _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  final _searchController = TextEditingController();
  final _minOrdersController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void dispose() {
    _searchController.dispose();
    _minOrdersController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final minOrders = int.tryParse(_minOrdersController.text.trim());
    final filter = AdminClientsFilter(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      minOrders: minOrders,
    );
    ref.read(adminClientsProvider.notifier).applyFilter(filter);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _minOrdersController.clear();
      _dateFrom = null;
      _dateTo = null;
    });
    ref.read(adminClientsProvider.notifier).clearFilter();
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
    final state = ref.watch(adminClientsProvider);
    final isFiltered = state.filter.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminClientsTitle),
        actions: [
          if (isFiltered)
            TextButton(
              onPressed: _clearFilters,
              child: Text(l10n.clear,
                  style: const TextStyle(color: AppColors.primary)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.adminSearchClients,
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
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.receipt_long_outlined,
                      label: _minOrdersController.text.isNotEmpty
                          ? '${l10n.adminMinOrders}: ${_minOrdersController.text}'
                          : l10n.adminMinOrders,
                      isActive: _minOrdersController.text.isNotEmpty,
                      onTap: () => _showMinOrdersDialog(context, l10n),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      body: state.isLoading && state.clients.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.clients.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminClientsProvider.notifier).load(),
                )
              : state.clients.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: l10n.adminNoClients,
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminClientsProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.clients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = state.clients[i];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  c.name?.isNotEmpty == true
                                      ? c.name![0].toUpperCase()
                                      : (c.phone.isNotEmpty
                                          ? c.phone[0]
                                          : '?'),
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  if (c.pharmacies.isNotEmpty)
                                    Text(
                                      c.pharmacies.join(', '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.8)),
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
                                  Text(
                                    l10n.adminClientsOrders,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showMinOrdersDialog(BuildContext context, AppL10n l10n) {
    final ctrl = TextEditingController(text: _minOrdersController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminMinOrders),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '2'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _minOrdersController.clear());
              Navigator.pop(ctx);
              _applyFilter();
            },
            child: Text(l10n.clear),
          ),
          TextButton(
            onPressed: () {
              setState(() => _minOrdersController.text = ctrl.text);
              Navigator.pop(ctx);
              _applyFilter();
            },
            child: Text(l10n.apply),
          ),
        ],
      ),
    );
  }
}

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
