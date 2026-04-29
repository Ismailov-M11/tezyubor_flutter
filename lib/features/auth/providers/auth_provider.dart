import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/auth_models.dart';

// ─── Locale ───────────────────────────────────────────────────────────────────

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_load());

  static Locale _load() {
    final saved = StorageService.getString(AppConstants.localeKey);
    return switch (saved) {
      'uz' => const Locale('uz'),
      'en' => const Locale('en'),
      _ => const Locale('ru'),
    };
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await StorageService.setString(AppConstants.localeKey, locale.languageCode);
  }
}

// ─── Theme ────────────────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadTheme());

  static ThemeMode _loadTheme() {
    final saved = StorageService.getString(AppConstants.themeKey);
    return switch (saved) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    StorageService.setString(
      AppConstants.themeKey,
      next == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  void setMode(ThemeMode mode) {
    state = mode;
    StorageService.setString(
      AppConstants.themeKey,
      switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        _ => 'system',
      },
    );
  }
}

// ─── Environment ──────────────────────────────────────────────────────────────

final environmentProvider =
    StateNotifierProvider<EnvironmentNotifier, AppEnvironment>(
  (ref) => EnvironmentNotifier(),
);

class EnvironmentNotifier extends StateNotifier<AppEnvironment> {
  EnvironmentNotifier() : super(_loadEnv());

  static AppEnvironment _loadEnv() {
    final saved = StorageService.getString(AppConstants.environmentKey);
    return saved == 'admin' ? AppEnvironment.admin : AppEnvironment.app;
  }

  void toggle() {
    final next =
        state == AppEnvironment.app ? AppEnvironment.admin : AppEnvironment.app;
    state = next;
    StorageService.setString(
      AppConstants.environmentKey,
      next == AppEnvironment.admin ? 'admin' : 'app',
    );
  }

  void set(AppEnvironment env) {
    state = env;
    StorageService.setString(
      AppConstants.environmentKey,
      env == AppEnvironment.admin ? 'admin' : 'app',
    );
  }
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final tokenFuture = StorageService.getToken();
    await Future.delayed(const Duration(seconds: 3));
    final token = await tokenFuture;
    final userJson = StorageService.getString(AppConstants.userKey);
    final user = AuthUser.fromJsonString(userJson);

    if (token != null && user != null) {
      state = AuthState(token: token, user: user, isInitialized: true);
    } else {
      state = const AuthState(isInitialized: true);
    }
  }

  Future<bool> loginPharmacy({
    required String login,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.post(
        '/auth/pharmacy/login',
        data: {'login': login, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final token = (data['token'] ?? data['accessToken'] ?? '').toString();
      if (token.isEmpty) throw Exception('Не получен токен от сервера');
      final userRaw = (data['user'] ?? data['pharmacy']) as Map<String, dynamic>;
      final user = AuthUser.fromJson(userRaw);

      await StorageService.setToken(token);
      await StorageService.setString(AppConstants.userKey, user.toJsonString());

      state = AuthState(token: token, user: user, isInitialized: true);
      return true;
    } on DioException catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.post(
        '/auth/admin/login',
        data: {'email': email, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final token = (data['token'] ?? data['accessToken'] ?? '').toString();
      if (token.isEmpty) throw Exception('Не получен токен от сервера');
      final userMap = (data['user'] ?? data['admin'] ?? data['adminUser']) as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);

      await StorageService.setToken(token);
      await StorageService.setString(AppConstants.userKey, user.toJsonString());

      state = AuthState(token: token, user: user, isInitialized: true);
      return true;
    } on DioException catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clear();
    state = const AuthState(); // isInitialized: false → роутер показывает splash
    await Future.delayed(const Duration(seconds: 3));
    state = const AuthState(isInitialized: true); // → роутер видит !isLoggedIn → /login
  }

  Future<void> clearRequiresLocation() async {
    final user = state.user;
    if (user == null) return;
    final updated = AuthUser(
      id: user.id,
      name: user.name,
      email: user.email,
      login: user.login,
      role: user.role,
      permissions: user.permissions,
      isSuperAdmin: user.isSuperAdmin,
      subscriptionExpiry: user.subscriptionExpiry,
      requiresLocation: false,
    );
    await StorageService.setString(AppConstants.userKey, updated.toJsonString());
    state = state.copyWith(user: updated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ??
          data['error'] as String? ??
          'Ошибка сервера';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Нет соединения с сервером';
    }
    return e.message ?? 'Неизвестная ошибка';
  }
}
