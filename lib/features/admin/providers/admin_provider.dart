import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_models.dart';

// ─── Admin Orders ─────────────────────────────────────────────────────────────

class AdminOrdersState {
  final List<AdminOrder> orders;
  final bool isLoading;
  final String? error;

  const AdminOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  AdminOrdersState copyWith({
    List<AdminOrder>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminOrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AdminOrdersNotifier extends StateNotifier<AdminOrdersState> {
  AdminOrdersNotifier() : super(const AdminOrdersState()) {
    load();
  }

  Future<void> load({
    String? status,
    String? pharmacyId,
    String? from,
    String? to,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get(
        '/admin/orders',
        params: {
          if (status != null) 'status': status,
          if (pharmacyId != null) 'pharmacyId': pharmacyId,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );
      final list = (response.data as List)
          .map((e) => AdminOrder.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(orders: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    }
  }

  Future<bool> confirmOrder(String token) async {
    try {
      await ApiClient.instance.put('/admin/orders/$token/confirm');
      await load();
      return true;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(String token) async {
    try {
      await ApiClient.instance.put('/admin/orders/$token/cancel');
      await load();
      return true;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<bool> deleteOrder(int id) async {
    try {
      await ApiClient.instance.delete('/admin/orders/$id');
      state = state.copyWith(
          orders: state.orders.where((o) => o.id != id).toList());
      return true;
    } on DioException catch (_) {
      return false;
    }
  }
}

final adminOrdersProvider =
    StateNotifierProvider<AdminOrdersNotifier, AdminOrdersState>(
  (ref) => AdminOrdersNotifier(),
);

// ─── Admin Pharmacies ─────────────────────────────────────────────────────────

class AdminPharmaciesState {
  final List<AdminPharmacy> pharmacies;
  final bool isLoading;
  final String? error;

  const AdminPharmaciesState({
    this.pharmacies = const [],
    this.isLoading = false,
    this.error,
  });

  AdminPharmaciesState copyWith({
    List<AdminPharmacy>? pharmacies,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminPharmaciesState(
        pharmacies: pharmacies ?? this.pharmacies,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AdminPharmaciesNotifier extends StateNotifier<AdminPharmaciesState> {
  AdminPharmaciesNotifier() : super(const AdminPharmaciesState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get(
        '/admin/pharmacies',
        params: {if (search != null && search.isNotEmpty) 'search': search},
      );
      final list = (response.data as List)
          .map((e) => AdminPharmacy.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(pharmacies: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ApiClient.instance.delete('/admin/pharmacies/$id');
      state = state.copyWith(
          pharmacies: state.pharmacies.where((p) => p.id != id).toList());
      return true;
    } on DioException catch (_) {
      return false;
    }
  }
}

final adminPharmaciesProvider =
    StateNotifierProvider<AdminPharmaciesNotifier, AdminPharmaciesState>(
  (ref) => AdminPharmaciesNotifier(),
);

// ─── Admin Analytics ──────────────────────────────────────────────────────────

class AdminAnalyticsState {
  final AdminAnalytics? data;
  final bool isLoading;
  final String? error;

  const AdminAnalyticsState({this.data, this.isLoading = false, this.error});

  AdminAnalyticsState copyWith({
    AdminAnalytics? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminAnalyticsState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AdminAnalyticsNotifier extends StateNotifier<AdminAnalyticsState> {
  AdminAnalyticsNotifier() : super(const AdminAnalyticsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get('/admin/analytics');
      final analytics =
          AdminAnalytics.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(data: analytics, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    }
  }
}

final adminAnalyticsProvider =
    StateNotifierProvider<AdminAnalyticsNotifier, AdminAnalyticsState>(
  (ref) => AdminAnalyticsNotifier(),
);

// ─── Admin Clients ────────────────────────────────────────────────────────────

class AdminClientsState {
  final List<AdminClient> clients;
  final bool isLoading;
  final String? error;

  const AdminClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
  });

  AdminClientsState copyWith({
    List<AdminClient>? clients,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminClientsState(
        clients: clients ?? this.clients,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AdminClientsNotifier extends StateNotifier<AdminClientsState> {
  AdminClientsNotifier() : super(const AdminClientsState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get(
        '/admin/clients',
        params: {if (search != null && search.isNotEmpty) 'search': search},
      );
      final list = (response.data as List)
          .map((e) => AdminClient.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(clients: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    }
  }
}

final adminClientsProvider =
    StateNotifierProvider<AdminClientsNotifier, AdminClientsState>(
  (ref) => AdminClientsNotifier(),
);

// ─── Admin Activations ────────────────────────────────────────────────────────

class AdminActivationsState {
  final List<AdminActivation> activations;
  final bool isLoading;
  final String? error;

  const AdminActivationsState({
    this.activations = const [],
    this.isLoading = false,
    this.error,
  });

  AdminActivationsState copyWith({
    List<AdminActivation>? activations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminActivationsState(
        activations: activations ?? this.activations,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AdminActivationsNotifier extends StateNotifier<AdminActivationsState> {
  AdminActivationsNotifier() : super(const AdminActivationsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get('/admin/activations');
      final list = (response.data as List)
          .map((e) => AdminActivation.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(activations: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    }
  }
}

final adminActivationsProvider =
    StateNotifierProvider<AdminActivationsNotifier, AdminActivationsState>(
  (ref) => AdminActivationsNotifier(),
);

// ─── Admin Roles ──────────────────────────────────────────────────────────────

class AdminRolesState {
  final List<AdminRole> roles;
  final bool isLoading;
  final String? error;

  const AdminRolesState({
    this.roles = const [],
    this.isLoading = false,
    this.error,
  });

  AdminRolesState copyWith({
    List<AdminRole>? roles,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminRolesState(
        roles: roles ?? this.roles,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AdminRolesNotifier extends StateNotifier<AdminRolesState> {
  AdminRolesNotifier() : super(const AdminRolesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get('/admin/roles');
      final list = (response.data as List)
          .map((e) => AdminRole.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(roles: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ApiClient.instance.delete('/admin/roles/$id');
      state =
          state.copyWith(roles: state.roles.where((r) => r.id != id).toList());
      return true;
    } on DioException catch (_) {
      return false;
    }
  }
}

final adminRolesProvider =
    StateNotifierProvider<AdminRolesNotifier, AdminRolesState>(
  (ref) => AdminRolesNotifier(),
);
