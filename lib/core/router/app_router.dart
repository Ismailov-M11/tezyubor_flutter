import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/models/auth_models.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/pharmacy/screens/pharmacy_main_screen.dart';
import '../../features/admin/screens/admin_main_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation.startsWith('/login');

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) {
        if (authState.user?.role == UserRole.admin) return '/admin';
        return '/pharmacy';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pharmacy',
        redirect: (context, state) => '/pharmacy/orders',
      ),
      GoRoute(
        path: '/pharmacy/:tab',
        builder: (context, state) {
          final tab = state.pathParameters['tab'] ?? 'orders';
          return PharmacyMainScreen(initialTab: tab);
        },
        routes: [
          GoRoute(
            path: 'orders/create',
            builder: (context, state) => const PharmacyMainScreen(
              initialTab: 'orders',
              openCreateOrder: true,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/orders',
      ),
      GoRoute(
        path: '/admin/:tab',
        builder: (context, state) {
          final tab = state.pathParameters['tab'] ?? 'orders';
          return AdminMainScreen(initialTab: tab);
        },
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}
