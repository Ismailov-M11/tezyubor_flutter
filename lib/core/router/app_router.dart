import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/models/auth_models.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/pharmacy/screens/location/location_picker_screen.dart';
import '../../features/pharmacy/screens/pharmacy_main_screen.dart';
import '../../features/admin/screens/admin_main_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';
      final isLoginRoute = loc.startsWith('/login');

      if (!authState.isInitialized) return isSplash ? null : '/splash';

      final isLoggedIn = authState.isAuthenticated;
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && (isLoginRoute || isSplash)) {
        if (authState.user?.role == UserRole.admin) return '/admin';
        if (authState.user?.requiresLocation == true) return '/pharmacy/location-setup';
        return '/pharmacy';
      }
      if (!isLoggedIn && isSplash) return '/login';
      // Удерживаем на экране выбора локации пока флаг не снят
      if (isLoggedIn &&
          authState.user?.role == UserRole.pharmacy &&
          authState.user?.requiresLocation == true &&
          loc != '/pharmacy/location-setup') {
        return '/pharmacy/location-setup';
      }
      // Локация сохранена — уходим с экрана настройки на заказы
      if (isLoggedIn &&
          authState.user?.role == UserRole.pharmacy &&
          authState.user?.requiresLocation != true &&
          loc == '/pharmacy/location-setup') {
        return '/pharmacy/orders';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pharmacy/location-setup',
        builder: (_, __) => const LocationPickerScreen(isSetupMode: true),
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
