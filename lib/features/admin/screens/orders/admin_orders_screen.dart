import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/utils/uz_phone_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';

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
  Timer? _debounce;
  bool _searchVisible = false;

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
    _debounce?.cancel();
    super.dispose();
  }

  String _tabLabel(String status, AppL10n l10n) {
    if (status == 'all') return l10n.adminStatusAll;
    return StatusBadge.labelFor(status);
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final f = ref.read(adminOrdersProvider).filter.copyWith(
            search: v,
            clearSearch: v.isEmpty,
          );
      ref.read(adminOrdersProvider.notifier).applyFilter(f);
    });
  }

  void _toggleSearch() {
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _searchController.clear();
      final f = ref
          .read(adminOrdersProvider)
          .filter
          .copyWith(clearSearch: true);
      ref.read(adminOrdersProvider.notifier).applyFilter(f);
    }
  }

  void _openFilter() {
    final current = ref.read(adminOrdersProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AdminOrderFilterSheet(
        current: current,
        onApply: (f) =>
            ref.read(adminOrdersProvider.notifier).applyFilter(f),
        onClear: () =>
            ref.read(adminOrdersProvider.notifier).clearFilter(),
      ),
    );
  }

  void _openCreate() {
    final pharmacies =
        ref.read(adminPharmaciesProvider).pharmacies;
    if (pharmacies.isEmpty) {
      ref.read(adminPharmaciesProvider.notifier).load();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreateOrderSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(adminOrdersProvider);
    final me = ref.watch(adminMeProvider);
    final hasFilter = state.filter.isActive;

    final canCreate =
        me.isSuperAdmin || me.permissions.contains('orders:create');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminOrdersTitle),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.search_off : Icons.search),
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
                      hintText: l10n.adminSearchOrders,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                ref
                                    .read(adminOrdersProvider.notifier)
                                    .applyFilter(ref
                                        .read(adminOrdersProvider)
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
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                indicatorWeight: 2,
                indicatorColor: AppColors.primary,
                dividerColor: Colors.transparent,
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
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _openCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 26),
            )
          : null,
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _AdminOrderFilterSheet extends StatefulWidget {
  final AdminOrdersFilter current;
  final void Function(AdminOrdersFilter) onApply;
  final VoidCallback onClear;

  const _AdminOrderFilterSheet({
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_AdminOrderFilterSheet> createState() =>
      _AdminOrderFilterSheetState();
}

class _AdminOrderFilterSheetState extends State<_AdminOrderFilterSheet> {
  String? _courier;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  bool _courierExpanded = true;
  bool _dateExpanded = false;

  @override
  void initState() {
    super.initState();
    _courier = widget.current.courier;
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

  int get _count =>
      (_courier != null ? 1 : 0) +
      (_dateFrom != null ? 1 : 0) +
      (_dateTo != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (_, scroll) => Column(
        children: [
          Container(
            width: 40, height: 4,
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
                if (_count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$_count',
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
                  title: l10n.adminOrderCourier,
                  count: _courier != null ? 1 : 0,
                  expanded: _courierExpanded,
                  onToggle: () =>
                      setState(() => _courierExpanded = !_courierExpanded),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ToggleChip(
                        label: l10n.adminCourierAll,
                        selected: _courier == null,
                        color: AppColors.primary,
                        onTap: () => setState(() => _courier = null),
                      ),
                      ..._allCouriers.map((c) => _ToggleChip(
                            label: c[0].toUpperCase() + c.substring(1),
                            selected: _courier == c,
                            color: AppColors.primary,
                            onTap: () => setState(() =>
                                _courier = _courier == c ? null : c),
                          )),
                    ],
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
                          icon:
                              const Icon(Icons.calendar_today, size: 15),
                          label: Text(
                            _dateFrom != null
                                ? _fmt(_dateFrom!)
                                : l10n.from,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon:
                              const Icon(Icons.calendar_today, size: 15),
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
                          onPressed: () => setState(() {
                            _dateFrom = null;
                            _dateTo = null;
                          }),
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
                  widget.onApply(AdminOrdersFilter(
                    search: widget.current.search,
                    courier: _courier,
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

// ─── Create order sheet ───────────────────────────────────────────────────────

class _CreateOrderSheet extends ConsumerStatefulWidget {
  const _CreateOrderSheet();

  @override
  ConsumerState<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<_CreateOrderSheet> {
  final _commentCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _selectedPharmacyId;
  String? _selectedPharmacyName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_onPhoneChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(adminPharmaciesProvider).pharmacies.isEmpty) {
        ref.read(adminPharmaciesProvider.notifier).load();
      }
    });
  }

  void _onPhoneChanged() {
    if (UzPhoneFormatter.isComplete(_phoneCtrl.text)) {
      final digits = UzPhoneFormatter.digitsOnly(_phoneCtrl.text);
      final clients = ref.read(adminClientsProvider).clients;
      final match = clients.where((c) =>
          UzPhoneFormatter.digitsOnly(c.phone) == digits).firstOrNull;
      if (match?.name != null && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = match!.name!;
      }
    }
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_onPhoneChanged);
    _commentCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_selectedPharmacyId == null) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(adminOrdersProvider.notifier).createOrder(
          pharmacyId: _selectedPharmacyId!,
          comment: _commentCtrl.text.trim(),
          medicinesTotal: double.tryParse(_amountCtrl.text.trim()),
          customerPhone: _phoneCtrl.text.trim(),
          customerName: _nameCtrl.text.trim(),
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adminOrderCreated)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pharmacies = ref.watch(adminPharmaciesProvider).pharmacies;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scroll) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(l10n.adminCreateOrderTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  // Pharmacy selector
                  Text(l10n.adminSelectPharmacy,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showPharmacyPicker(context, pharmacies),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedPharmacyId == null
                              ? Theme.of(context).colorScheme.outline
                              : AppColors.primary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedPharmacyName ??
                                  l10n.adminSelectPharmacy,
                              style: TextStyle(
                                color: _selectedPharmacyId == null
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                    : null,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.orderCommentLbl,
                      hintText: l10n.orderCommentHint,
                      prefixIcon:
                          const Icon(Icons.comment_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.orderAmountLbl,
                      prefixIcon:
                          const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.customer,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [UzPhoneFormatter()],
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ||
                              _selectedPharmacyId == null
                          ? null
                          : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : Text(l10n.adminCreateOrder),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPharmacyPicker(
      BuildContext context, List<AdminPharmacy> pharmacies) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PharmacyPickerSheet(
        pharmacies: pharmacies,
        selectedId: _selectedPharmacyId,
        l10n: l10n,
        onSelected: (p) {
          setState(() {
            _selectedPharmacyId = p.id;
            _selectedPharmacyName = p.name;
          });
        },
      ),
    );
  }
}

class _PharmacyPickerSheet extends StatefulWidget {
  final List<AdminPharmacy> pharmacies;
  final String? selectedId;
  final AppL10n l10n;
  final void Function(AdminPharmacy) onSelected;

  const _PharmacyPickerSheet({
    required this.pharmacies,
    required this.selectedId,
    required this.l10n,
    required this.onSelected,
  });

  @override
  State<_PharmacyPickerSheet> createState() => _PharmacyPickerSheetState();
}

class _PharmacyPickerSheetState extends State<_PharmacyPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<AdminPharmacy> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.pharmacies;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.pharmacies
          : widget.pharmacies
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.login.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scroll) => Column(
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(l10n.adminSelectPharmacy,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final p = _filtered[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.login),
                  selected: widget.selectedId == p.id,
                  selectedColor: AppColors.primary,
                  onTap: () {
                    widget.onSelected(p);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab list ─────────────────────────────────────────────────────────────────

class _AdminTabOrderList extends ConsumerWidget {
  final List<AdminOrder> orders;
  final AppL10n l10n;

  const _AdminTabOrderList(
      {super.key, required this.orders, required this.l10n});

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _AdminOrderCard(
          order: orders[i],
          l10n: l10n,
          onTap: () => _showDetail(context, orders[i], l10n),
        ),
      ),
    );
  }

  void _showDetail(
      BuildContext context, AdminOrder order, AppL10n l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AdminOrderDetailSheet(order: order),
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _AdminOrderCard extends ConsumerWidget {
  final AdminOrder order;
  final AppL10n l10n;
  final VoidCallback onTap;

  const _AdminOrderCard(
      {required this.order, required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(adminMeProvider);
    final canConfirm =
        me.isSuperAdmin || me.permissions.contains('orders:confirm');
    final canCancel =
        me.isSuperAdmin || me.permissions.contains('orders:cancel');

    final statusColor = StatusBadge.colorFor(order.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
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
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: AppColors.primary),
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
                            l10n.adminOrderCourier,
                            order.selectedCourier!.toUpperCase()),
                      _row(context, Icons.access_time, l10n.adminOrderDate,
                          _formatDate(order.createdAt)),
                      if (order.status == 'awaiting_confirmation' &&
                          (canConfirm || canCancel)) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (canConfirm)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _confirmOrder(context, ref),
                                  style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 36)),
                                  child: Text(l10n.adminConfirmOrder),
                                ),
                              ),
                            if (canCancel) ...[
                              if (canConfirm) const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _cancelOrder(context, ref),
                                icon: const Icon(Icons.cancel_outlined,
                                    color: AppColors.warning),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      AppColors.warning.withValues(alpha: 0.1),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
          BuildContext ctx, IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('$label: ',
                style: Theme.of(ctx).textTheme.bodySmall),
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
    final ok = await ref
        .read(adminOrdersProvider.notifier)
        .confirmOrder(order.token);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? context.l10n.adminOrderConfirmed
              : context.l10n.adminOrderError)));
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminCancelOrder),
        content: Text(l10n.adminDeleteOrderMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.warning),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(adminOrdersProvider.notifier)
          .cancelOrder(order.token);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? context.l10n.adminOrderCancelled
                : context.l10n.adminOrderError)));
      }
    }
  }

}

// ─── Order detail sheet ───────────────────────────────────────────────────────

class _AdminOrderDetailSheet extends ConsumerWidget {
  final AdminOrder order;
  const _AdminOrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final me = ref.watch(adminMeProvider);
    final canConfirm =
        me.isSuperAdmin || me.permissions.contains('orders:confirm');
    final canCancel =
        me.isSuperAdmin || me.permissions.contains('orders:cancel');
    final canDelete =
        me.isSuperAdmin || me.permissions.contains('orders:delete');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scroll) => Column(
        children: [
          Container(
            width: 40, height: 4,
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
                            fontFamily: 'monospace'),
                      ),
                      Text(
                        _fmtDate(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurfaceVariant),
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
                if (order.pharmacyName != null) ...[
                  _SectionTitle(l10n.adminPharmacyLbl),
                  _SectionCard(children: [
                    _DetailRow(
                        icon: Icons.storefront_outlined,
                        label: l10n.adminPharmacyLbl,
                        value: order.pharmacyName!),
                    if (order.pharmacyPhone != null)
                      _DetailRow(
                          icon: Icons.phone_outlined,
                          label: l10n.phone,
                          value: order.pharmacyPhone!),
                    if (order.pharmacyAddress != null)
                      _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: l10n.address,
                          value: order.pharmacyAddress!),
                  ]),
                  const SizedBox(height: 12),
                ],
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
                _SectionTitle(l10n.totalCost),
                _SectionCard(children: [
                  _DetailRow(
                      icon: Icons.shopping_bag_outlined,
                      label: l10n.adminOrderSum,
                      value:
                          '${order.medicinesTotal.toStringAsFixed(0)} сум'),
                  if (order.deliveryPrice != null)
                    _DetailRow(
                        icon: Icons.delivery_dining,
                        label: l10n.deliveryCost,
                        value:
                            '${order.deliveryPrice!.toStringAsFixed(0)} сум'),
                  if (order.totalPrice != null)
                    _DetailRow(
                        icon: Icons.receipt_outlined,
                        label: l10n.totalAmountLbl,
                        value:
                            '${order.totalPrice!.toStringAsFixed(0)} сум',
                        bold: true,
                        valueColor: AppColors.primary),
                ]),
                if (order.selectedCourier != null) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(l10n.courier),
                  _SectionCard(children: [
                    _DetailRow(
                        icon: Icons.local_shipping_outlined,
                        label: l10n.courier,
                        value: order.selectedCourier!.toUpperCase()),
                    if (order.trackingUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () async {
                            final uri = Uri.tryParse(order.trackingUrl!);
                            if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                l10n.trackingLink,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ],
                const SizedBox(height: 16),
                if (canCancel &&
                    order.status != 'cancelled' &&
                    order.status != 'delivered') ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.adminCancelOrder),
                            content: Text(l10n.adminDeleteOrderMsg),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel)),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                                child: Text(l10n.yes),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          final ok = await ref
                              .read(adminOrdersProvider.notifier)
                              .cancelOrder(order.token);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(ok ? l10n.adminOrderCancelled : l10n.adminOrderError)));
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(l10n.adminCancelOrder),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (canConfirm && order.status == 'awaiting_confirmation') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final ok = await ref
                            .read(adminOrdersProvider.notifier)
                            .confirmOrder(order.token);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok ? l10n.adminOrderConfirmed : l10n.adminOrderError)));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(l10n.adminConfirmOrder),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (canDelete)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.adminDeleteOrder),
                            content: Text(l10n.adminDeleteOrderMsg),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel)),
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
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      label: Text(l10n.adminDeleteOrder.replaceAll('?', '')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
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
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: bold
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: valueColor,
                        ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
}

// ─── Filter section ───────────────────────────────────────────────────────────

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
                color:
                    theme.colorScheme.outline.withValues(alpha: 0.3)),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? color
                    : color.withValues(alpha: 0.3)),
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
