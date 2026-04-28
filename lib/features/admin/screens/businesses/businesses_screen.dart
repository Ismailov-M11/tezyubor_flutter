import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';

class BusinessesScreen extends ConsumerStatefulWidget {
  const BusinessesScreen({super.key});

  @override
  ConsumerState<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends ConsumerState<BusinessesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(adminPharmaciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminBusinessesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminPharmaciesProvider.notifier).load(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.adminSearchBusiness,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref.read(adminPharmaciesProvider.notifier).load();
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                if (v.length >= 2 || v.isEmpty) {
                  ref
                      .read(adminPharmaciesProvider.notifier)
                      .load(search: v.isEmpty ? null : v);
                }
              },
            ),
          ),
        ),
      ),
      body: state.isLoading && state.pharmacies.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.pharmacies.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminPharmaciesProvider.notifier).load(),
                )
              : state.pharmacies.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: l10n.adminNoBusinesses,
                      subtitle: l10n.adminNoBusinessesSub,
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminPharmaciesProvider.notifier).load(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.pharmacies.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _PharmacyCard(pharmacy: state.pharmacies[i]),
                      ),
                    ),
    );
  }
}

class _PharmacyCard extends ConsumerWidget {
  final AdminPharmacy pharmacy;

  const _PharmacyCard({required this.pharmacy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final daysLeft = _daysLeft(pharmacy.subscriptionExpiry);
    final isExpiringSoon = daysLeft != null && daysLeft <= 14;
    final isExpired = daysLeft != null && daysLeft <= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: pharmacy.isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.mutedForegroundLight.withValues(alpha: 0.15),
                  child: Text(
                    pharmacy.name.isNotEmpty ? pharmacy.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: pharmacy.isActive
                          ? AppColors.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pharmacy.name, style: theme.textTheme.titleSmall),
                      Text(pharmacy.login, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pharmacy.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pharmacy.isActive
                        ? l10n.adminBusinessActive
                        : l10n.adminBusinessInactive,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: pharmacy.isActive
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pharmacy.phone != null)
              _row(context, Icons.phone_outlined, pharmacy.phone!),
            if (pharmacy.address != null)
              _row(context, Icons.location_on_outlined, pharmacy.address!),
            _row(context, Icons.receipt_long_outlined,
                '${pharmacy.ordersCount} ${l10n.adminBusinessOrders}'),
            if (pharmacy.allowedCouriers != null &&
                pharmacy.allowedCouriers!.isNotEmpty)
              _row(context, Icons.local_shipping_outlined,
                  pharmacy.allowedCouriers!),
            if (pharmacy.subscriptionExpiry != null) ...[
              const SizedBox(height: 8),
              _SubscriptionBar(
                l10n: l10n,
                expiry: pharmacy.subscriptionExpiry!,
                daysLeft: daysLeft ?? 0,
                isExpired: isExpired,
                isExpiringSoon: isExpiringSoon,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext ctx, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: Theme.of(ctx).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  int? _daysLeft(String? expiry) {
    if (expiry == null) return null;
    final dt = DateTime.tryParse(expiry);
    if (dt == null) return null;
    return dt.difference(DateTime.now()).inDays;
  }
}

class _SubscriptionBar extends StatelessWidget {
  final AppL10n l10n;
  final String expiry;
  final int daysLeft;
  final bool isExpired;
  final bool isExpiringSoon;

  const _SubscriptionBar({
    required this.l10n,
    required this.expiry,
    required this.daysLeft,
    required this.isExpired,
    required this.isExpiringSoon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpired
        ? AppColors.error
        : isExpiringSoon
            ? AppColors.warning
            : AppColors.success;

    final label = isExpired
        ? l10n.adminSubExpired
        : '${l10n.adminSubDays} $daysLeft ${l10n.adminSubDaysSuffix}';

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 13, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
