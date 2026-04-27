import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/auth_models.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadTheme());

  static ThemeMode _loadTheme() {
    final saved = StorageService.getString(AppConstants.themeKey);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.system;
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
      mode == ThemeMode.dark ? 'dark' : 'light',
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
    final token = await StorageService.getToken();
    final userJson = StorageService.getString(AppConstants.userKey);
    final user = AuthUser.fromJsonString(userJson);

    if (token != null && user != null) {
      state = AuthState(token: token, user: user);
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
      final data = response.data as Map<String, dynamic>;
      debugPrint('[AUTH] loginPharmacy response: $data');
      final token = (data['token'] ?? data['accessToken'] ?? '').toString();
      final pharmacyRaw = data['pharmacy'] ?? data['user'] ?? data;
      final user = AuthUser.fromJson(pharmacyRaw as Map<String, dynamic>);

      await StorageService.setToken(token);
      await StorageService.setString(AppConstants.userKey, user.toJsonString());

      state = AuthState(token: token, user: user);
      return true;
    } on DioException catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(isLoading: false, error: msg);
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
      final data = response.data as Map<String, dynamic>;
      debugPrint('[AUTH] loginAdmin response: $data');
      final token = (data['token'] ?? data['accessToken'] ?? '').toString();
      final userMap = (data['admin'] ?? data['adminUser'] ?? data['user'] ?? data) as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);

      await StorageService.setToken(token);
      await StorageService.setString(AppConstants.userKey, user.toJsonString());

      state = AuthState(token: token, user: user);
      return true;
    } on DioException catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clear();
    state = const AuthState();
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
