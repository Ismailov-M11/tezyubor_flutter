import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/models/auth_models.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'orders/admin_orders_screen.dart';
import 'businesses/businesses_screen.dart';
import 'analytics/admin_analytics_screen.dart';
import 'clients/admin_clients_screen.dart';
import 'activations/activations_screen.dart';
import 'roles/roles_screen.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  final String initialTab;

  const AdminMainScreen({super.key, this.initialTab = 'orders'});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabIndexFromString(widget.initialTab);
  }

  List<_AdminTab> _buildTabs(AuthUser user) {
    final tabs = <_AdminTab>[
      const _AdminTab(
        key: 'orders',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Заказы',
        permission: 'orders:view',
      ),
      const _AdminTab(
        key: 'businesses',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: 'Магазины',
        permission: 'pharmacies:view',
      ),
      const _AdminTab(
        key: 'analytics',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: 'Аналитика',
        permission: 'analytics:view',
      ),
      const _AdminTab(
        key: 'clients',
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Клиенты',
        permission: 'clients:view',
      ),
      const _AdminTab(
        key: 'activations',
        icon: Icons.how_to_reg_outlined,
        activeIcon: Icons.how_to_reg,
        label: 'Активации',
        permission: 'activations:view',
      ),
    ];

    if (user.isSuperAdmin) {
      tabs.add(const _AdminTab(
        key: 'roles',
        icon: Icons.manage_accounts_outlined,
        activeIcon: Icons.manage_accounts,
        label: 'Роли',
        permission: null,
      ));
    }

    return tabs
        .where((t) => t.permission == null || user.hasPermission(t.permission!))
        .toList();
  }

  int _tabIndexFromString(String tab) {
    const order = ['orders', 'businesses', 'analytics', 'clients', 'activations', 'roles'];
    final idx = order.indexOf(tab);
    return idx < 0 ? 0 : idx;
  }

  Widget _buildPage(String key) => switch (key) {
        'businesses' => const BusinessesScreen(),
        'analytics' => const AdminAnalyticsScreen(),
        'clients' => const AdminClientsScreen(),
        'activations' => const ActivationsScreen(),
        'roles' => const RolesScreen(),
        _ => const AdminOrdersScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) return const SizedBox();

    final tabs = _buildTabs(user);
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => _buildPage(t.key)).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.activeIcon, color: AppColors.primary),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _AdminTab {
  final String key;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? permission;

  const _AdminTab({
    required this.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.permission,
  });
}
