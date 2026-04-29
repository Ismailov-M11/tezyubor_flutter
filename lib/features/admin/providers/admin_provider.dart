import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _dioError(DioException e) =>
    e.response?.data?['message'] as String? ?? 'Ошибка загрузки';

// ─── Admin Me (permissions) ────────────────────────────────────────────────────

class AdminMeState {
  final bool isSuperAdmin;
  final List<String> permissions;
  final bool isLoading;

  const AdminMeState({
    this.isSuperAdmin = false,
    this.permissions = const [],
    this.isLoading = false,
  });

  AdminMeState copyWith({
    bool? isSuperAdmin,
    List<String>? permissions,
    bool? isLoading,
  }) =>
      AdminMeState(
        isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
        permissions: permissions ?? this.permissions,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AdminMeNotifier extends StateNotifier<AdminMeState> {
  AdminMeNotifier() : super(const AdminMeState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient.instance.get('/admin/me');
      final data = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      final isSuperAdmin = data['isSuperAdmin'] as bool? ?? false;
      final perms = isSuperAdmin
          ? <String>[]
          : (data['permissions'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
      state = AdminMeState(
        isSuperAdmin: isSuperAdmin,
        permissions: perms,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final adminMeProvider =
    StateNotifierProvider<AdminMeNotifier, AdminMeState>(
  (ref) => AdminMeNotifier(),
);

// ─── Admin Orders ─────────────────────────────────────────────────────────────

class AdminOrdersFilter {
  final String? search;
  final String? status;
  final String? courier;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;

  const AdminOrdersFilter({
    this.search,
    this.status,
    this.courier,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 30,
  });

  AdminOrdersFilter copyWith({
    String? search,
    String? status,
    String? courier,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? page,
    int? limit,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearCourier = false,
    bool clearDates = false,
  }) =>
      AdminOrdersFilter(
        search: clearSearch ? null : search ?? this.search,
        status: clearStatus ? null : status ?? this.status,
        courier: clearCourier ? null : courier ?? this.courier,
        dateFrom: clearDates ? null : dateFrom ?? this.dateFrom,
        dateTo: clearDates ? null : dateTo ?? this.dateTo,
        page: page ?? this.page,
        limit: limit ?? this.limit,
      );

  bool get isActive =>
      (search != null && search!.isNotEmpty) ||
      (status != null && status!.isNotEmpty) ||
      (courier != null && courier!.isNotEmpty) ||
      dateFrom != null ||
      dateTo != null;
}

class AdminOrdersState {
  final List<AdminOrder> orders;
  final bool isLoading;
  final String? error;
  final AdminOrdersFilter filter;
  final int total;
  final int pages;

  const AdminOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.filter = const AdminOrdersFilter(),
    this.total = 0,
    this.pages = 1,
  });

  AdminOrdersState copyWith({
    List<AdminOrder>? orders,
    bool? isLoading,
    String? error,
    AdminOrdersFilter? filter,
    int? total,
    int? pages,
    bool clearError = false,
  }) =>
      AdminOrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        filter: filter ?? this.filter,
        total: total ?? this.total,
        pages: pages ?? this.pages,
      );
}

class AdminOrdersNotifier extends StateNotifier<AdminOrdersState> {
  AdminOrdersNotifier() : super(const AdminOrdersState()) {
    load();
  }

  Future<void> load({AdminOrdersFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, clearError: true, filter: f);
    try {
      final params = <String, dynamic>{
        'page': f.page,
        'limit': f.limit,
      };
      if (f.search != null && f.search!.isNotEmpty) {
        params['search'] = f.search;
      }
      if (f.status != null && f.status!.isNotEmpty) {
        params['status'] = f.status;
      }
      if (f.courier != null && f.courier!.isNotEmpty) {
        params['courier'] = f.courier;
      }
      if (f.dateFrom != null) {
        params['dateFrom'] = f.dateFrom!.toIso8601String().split('T')[0];
      }
      if (f.dateTo != null) {
        params['dateTo'] = f.dateTo!.toIso8601String().split('T')[0];
      }

      final response =
          await ApiClient.instance.get('/admin/orders', params: params);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final rawList =
          (data['orders'] ?? data['data'] ?? []) as List;
      final orders = rawList
          .map((e) => AdminOrder.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        orders: orders,
        isLoading: false,
        total: (data['total'] as num?)?.toInt() ?? orders.length,
        pages: (data['pages'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilter(AdminOrdersFilter filter) =>
      load(filter: filter.copyWith(page: 1));

  Future<void> clearFilter() => load(filter: const AdminOrdersFilter());

  Future<bool> confirmOrder(String token) async {
    try {
      await ApiClient.instance.put('/admin/orders/$token/confirm');
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(String token) async {
    try {
      await ApiClient.instance.put('/admin/orders/$token/cancel');
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    try {
      await ApiClient.instance.delete('/admin/orders/$id');
      state = state.copyWith(
          orders: state.orders.where((o) => o.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createOrder({
    required String pharmacyId,
    String? comment,
    double? medicinesTotal,
    String? customerPhone,
    String? customerName,
  }) async {
    try {
      final data = <String, dynamic>{'pharmacyId': pharmacyId};
      if (comment != null && comment.isNotEmpty) {
        data['pharmacyComment'] = comment;
      }
      if (medicinesTotal != null) data['medicinesTotal'] = medicinesTotal;
      if (customerPhone != null && customerPhone.isNotEmpty) {
        data['customerPhone'] = customerPhone;
      }
      if (customerName != null && customerName.isNotEmpty) {
        data['customerName'] = customerName;
      }
      await ApiClient.instance.post('/admin/orders', data: data);
      await load();
      return true;
    } catch (_) {
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

  Future<void> load({String? search, String? isActive, String? courier}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (isActive != null) params['isActive'] = isActive;
      if (courier != null && courier.isNotEmpty) params['courier'] = courier;

      final response = await ApiClient.instance
          .get('/admin/pharmacies', params: params.isEmpty ? null : params);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final rawList = (data['pharmacies'] ?? data['data'] ?? []) as List;
      final list = rawList
          .map((e) => AdminPharmacy.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(pharmacies: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String name,
    required String phone,
    required String login,
    required String password,
    required String subscriptionExpiry,
    String? ownerName,
    String? address,
    String? allowedCouriers,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'phone': phone,
        'login': login,
        'password': password,
        'subscriptionExpiry': subscriptionExpiry,
      };
      if (ownerName != null && ownerName.isNotEmpty) data['ownerName'] = ownerName;
      if (address != null && address.isNotEmpty) data['address'] = address;
      if (allowedCouriers != null && allowedCouriers.isNotEmpty) {
        data['allowedCouriers'] = allowedCouriers;
      }
      await ApiClient.instance.post('/admin/pharmacies', data: data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(
    String id, {
    String? name,
    String? ownerName,
    String? address,
    String? phone,
    String? subscriptionExpiry,
    bool? isActive,
    String? login,
    String? newPassword,
    String? allowedCouriers,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (ownerName != null) data['ownerName'] = ownerName;
      if (address != null) data['address'] = address;
      if (phone != null) data['phone'] = phone;
      if (subscriptionExpiry != null) {
        data['subscriptionExpiry'] = subscriptionExpiry;
      }
      if (isActive != null) data['isActive'] = isActive;
      if (login != null && login.isNotEmpty) data['login'] = login;
      if (newPassword != null && newPassword.isNotEmpty) {
        data['newPassword'] = newPassword;
      }
      if (allowedCouriers != null) data['allowedCouriers'] = allowedCouriers;
      await ApiClient.instance.put('/admin/pharmacies/$id', data: data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ApiClient.instance.delete('/admin/pharmacies/$id');
      state = state.copyWith(
          pharmacies: state.pharmacies.where((p) => p.id != id).toList());
      return true;
    } catch (_) {
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
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final analytics = AdminAnalytics.fromJson(data);
      state = state.copyWith(data: analytics, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminAnalyticsProvider =
    StateNotifierProvider<AdminAnalyticsNotifier, AdminAnalyticsState>(
  (ref) => AdminAnalyticsNotifier(),
);

// ─── Admin Clients ────────────────────────────────────────────────────────────

class AdminClientsFilter {
  final String? search;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? minOrders;
  final String? pharmacyId;

  const AdminClientsFilter({
    this.search,
    this.dateFrom,
    this.dateTo,
    this.minOrders,
    this.pharmacyId,
  });

  AdminClientsFilter copyWith({
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minOrders,
    String? pharmacyId,
    bool clearSearch = false,
    bool clearDates = false,
    bool clearMinOrders = false,
  }) =>
      AdminClientsFilter(
        search: clearSearch ? null : search ?? this.search,
        dateFrom: clearDates ? null : dateFrom ?? this.dateFrom,
        dateTo: clearDates ? null : dateTo ?? this.dateTo,
        minOrders: clearMinOrders ? null : minOrders ?? this.minOrders,
        pharmacyId: pharmacyId ?? this.pharmacyId,
      );

  bool get isActive =>
      (search != null && search!.isNotEmpty) ||
      dateFrom != null ||
      dateTo != null ||
      (minOrders != null && minOrders! > 0);
}

class AdminClientsState {
  final List<AdminClient> clients;
  final bool isLoading;
  final String? error;
  final AdminClientsFilter filter;

  const AdminClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
    this.filter = const AdminClientsFilter(),
  });

  AdminClientsState copyWith({
    List<AdminClient>? clients,
    bool? isLoading,
    String? error,
    AdminClientsFilter? filter,
    bool clearError = false,
  }) =>
      AdminClientsState(
        clients: clients ?? this.clients,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        filter: filter ?? this.filter,
      );
}

class AdminClientsNotifier extends StateNotifier<AdminClientsState> {
  AdminClientsNotifier() : super(const AdminClientsState()) {
    load();
  }

  Future<void> load({AdminClientsFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, clearError: true, filter: f);
    try {
      final params = <String, dynamic>{};
      if (f.search != null && f.search!.isNotEmpty) {
        params['search'] = f.search;
      }
      if (f.dateFrom != null) {
        params['dateFrom'] = f.dateFrom!.toIso8601String().split('T')[0];
      }
      if (f.dateTo != null) {
        params['dateTo'] = f.dateTo!.toIso8601String().split('T')[0];
      }
      if (f.minOrders != null && f.minOrders! > 0) {
        params['minOrders'] = f.minOrders;
      }
      if (f.pharmacyId != null) {
        params['pharmacyId'] = f.pharmacyId;
      }

      final response = await ApiClient.instance.get('/admin/clients',
          params: params.isEmpty ? null : params);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final rawList = (data['clients'] ?? data['data'] ?? []) as List;
      final list = rawList
          .map((e) => AdminClient.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(clients: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilter(AdminClientsFilter filter) => load(filter: filter);
  Future<void> clearFilter() => load(filter: const AdminClientsFilter());
}

final adminClientsProvider =
    StateNotifierProvider<AdminClientsNotifier, AdminClientsState>(
  (ref) => AdminClientsNotifier(),
);

// ─── Admin Activations ────────────────────────────────────────────────────────

class AdminActivationsState {
  final List<AdminActivation> activations;
  final AdminActivationStats stats;
  final bool isLoading;
  final String? error;
  final AdminActivationsFilter filter;

  const AdminActivationsState({
    this.activations = const [],
    this.stats = const AdminActivationStats(),
    this.isLoading = false,
    this.error,
    this.filter = const AdminActivationsFilter(),
  });

  AdminActivationsState copyWith({
    List<AdminActivation>? activations,
    AdminActivationStats? stats,
    bool? isLoading,
    String? error,
    AdminActivationsFilter? filter,
    bool clearError = false,
  }) =>
      AdminActivationsState(
        activations: activations ?? this.activations,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        filter: filter ?? this.filter,
      );
}

class AdminActivationsNotifier extends StateNotifier<AdminActivationsState> {
  AdminActivationsNotifier() : super(const AdminActivationsState()) {
    load();
  }

  Future<void> load({AdminActivationsFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, clearError: true, filter: f);
    try {
      final params = <String, dynamic>{};
      if (f.search != null && f.search!.isNotEmpty) {
        params['search'] = f.search;
      }
      if (f.creatorType != null) params['creatorType'] = f.creatorType;
      if (f.status != null) params['status'] = f.status;
      if (f.dateFrom != null) {
        params['dateFrom'] = f.dateFrom!.toIso8601String().split('T')[0];
      }
      if (f.dateTo != null) {
        params['dateTo'] = f.dateTo!.toIso8601String().split('T')[0];
      }

      final response = await ApiClient.instance.get('/admin/activations',
          params: params.isEmpty ? null : params);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final rawList =
          (data['pharmacies'] ?? data['activations'] ?? data['data'] ?? [])
              as List;
      final list = rawList
          .map((e) => AdminActivation.fromJson(e as Map<String, dynamic>))
          .toList();
      final stats = AdminActivationStats.fromJson(data);
      state = state.copyWith(activations: list, stats: stats, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilter(AdminActivationsFilter filter) =>
      load(filter: filter);

  Future<void> clearFilter() =>
      load(filter: const AdminActivationsFilter());

  Future<bool> reassign(
    String pharmacyId, {
    String? createdById,
    bool selfRegistered = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'selfRegistered': selfRegistered,
        'createdById': createdById,
      };
      await ApiClient.instance.put(
        '/admin/pharmacies/$pharmacyId/creator',
        data: data,
      );
      await load();
      return true;
    } catch (_) {
      return false;
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
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final rawList = (data['roles'] ?? data['data'] ?? []) as List;
      final list = rawList
          .map((e) => AdminRole.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(roles: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create(String name, List<String> permissions) async {
    try {
      await ApiClient.instance.post('/admin/roles',
          data: {'name': name, 'permissions': permissions});
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(String id,
      {String? name, List<String>? permissions, bool? isActive}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (permissions != null) data['permissions'] = permissions;
      if (isActive != null) data['isActive'] = isActive;
      await ApiClient.instance.put('/admin/roles/$id', data: data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ApiClient.instance.delete('/admin/roles/$id');
      state = state.copyWith(
          roles: state.roles.where((r) => r.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminRolesProvider =
    StateNotifierProvider<AdminRolesNotifier, AdminRolesState>(
  (ref) => AdminRolesNotifier(),
);

// ─── Admin Users ──────────────────────────────────────────────────────────────

class AdminUsersState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  AdminUsersState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminUsersState(
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  AdminUsersNotifier() : super(const AdminUsersState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get('/admin/users');
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final rawList = (data['users'] ?? data['data'] ?? []) as List;
      final list = rawList
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(users: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String name,
    required String email,
    required String password,
    required List<String> roleIds,
    bool isActive = true,
  }) async {
    try {
      await ApiClient.instance.post('/admin/users', data: {
        'name': name,
        'email': email,
        'password': password,
        'roleIds': roleIds,
        'isActive': isActive,
      });
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(
    String id, {
    String? name,
    String? email,
    String? password,
    List<String>? roleIds,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (password != null && password.isNotEmpty) data['password'] = password;
      if (roleIds != null) data['roleIds'] = roleIds;
      if (isActive != null) data['isActive'] = isActive;
      await ApiClient.instance.put('/admin/users/$id', data: data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ApiClient.instance.delete('/admin/users/$id');
      state = state.copyWith(
          users: state.users.where((u) => u.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>(
  (ref) => AdminUsersNotifier(),
);
