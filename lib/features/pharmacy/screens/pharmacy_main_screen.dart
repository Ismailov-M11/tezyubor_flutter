import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'orders/orders_screen.dart';
import 'analytics/analytics_screen.dart';
import 'clients/clients_screen.dart';
import 'settings/settings_screen.dart';

class PharmacyMainScreen extends ConsumerStatefulWidget {
  final String initialTab;
  final bool openCreateOrder;

  const PharmacyMainScreen({
    super.key,
    this.initialTab = 'orders',
    this.openCreateOrder = false,
  });

  @override
  ConsumerState<PharmacyMainScreen> createState() => _PharmacyMainScreenState();
}

class _PharmacyMainScreenState extends ConsumerState<PharmacyMainScreen> {
  late int _currentIndex;

  final _tabs = const [
    _TabItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Заказы'),
    _TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Аналитика'),
    _TabItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Клиенты'),
    _TabItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Настройки'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabIndexFromString(widget.initialTab);
  }

  int _tabIndexFromString(String tab) => switch (tab) {
        'analytics' => 1,
        'clients' => 2,
        'settings' => 3,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final pages = [
      OrdersScreen(openCreate: widget.openCreateOrder),
      const AnalyticsScreen(),
      const ClientsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: _tabs
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

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
