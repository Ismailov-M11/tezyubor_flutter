import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrdersFilter {
  final String? search;
  final List<String> statuses;
  final List<String> couriers;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const OrdersFilter({
    this.search,
    this.statuses = const [],
    this.couriers = const [],
    this.dateFrom,
    this.dateTo,
  });

  bool get isActive =>
      (search != null && search!.isNotEmpty) ||
      statuses.isNotEmpty ||
      couriers.isNotEmpty ||
      dateFrom != null ||
      dateTo != null;

  OrdersFilter copyWith({
    String? search,
    List<String>? statuses,
    List<String>? couriers,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearSearch = false,
    bool clearDates = false,
    bool clearStatuses = false,
    bool clearCouriers = false,
  }) =>
      OrdersFilter(
        search: clearSearch ? null : search ?? this.search,
        statuses: clearStatuses ? [] : statuses ?? this.statuses,
        couriers: clearCouriers ? [] : couriers ?? this.couriers,
        dateFrom: clearDates ? null : dateFrom ?? this.dateFrom,
        dateTo: clearDates ? null : dateTo ?? this.dateTo,
      );
}

class OrdersState {
  final List<PharmacyOrder> orders;
  final bool isLoading;
  final String? error;
  final OrdersFilter filter;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.filter = const OrdersFilter(),
  });

  OrdersState copyWith({
    List<PharmacyOrder>? orders,
    bool? isLoading,
    String? error,
    OrdersFilter? filter,
    bool clearError = false,
  }) =>
      OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        filter: filter ?? this.filter,
      );
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier() : super(const OrdersState()) {
    load();
  }

  Future<void> load({OrdersFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, clearError: true, filter: f);
    try {
      final params = <String, dynamic>{};
      if (f.search != null && f.search!.isNotEmpty) params['search'] = f.search;
      if (f.statuses.isNotEmpty) params['status'] = f.statuses.join(',');
      if (f.couriers.isNotEmpty) params['courier'] = f.couriers.join(',');
      if (f.dateFrom != null) {
        params['dateFrom'] = f.dateFrom!.toIso8601String().split('T')[0];
      }
      if (f.dateTo != null) {
        params['dateTo'] = f.dateTo!.toIso8601String().split('T')[0];
      }

      final response = await ApiClient.instance.get(
        '/pharmacy/orders',
        params: params.isEmpty ? null : params,
      );
      final body = response.data as Map<String, dynamic>;
      final dataField = body['data'];
      final List rawList = dataField is List
          ? dataField
          : dataField is Map
              ? ((dataField['orders'] ?? dataField['items'] ?? []) as List)
              : [];
      final list = rawList
          .map((e) => PharmacyOrder.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(orders: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilter(OrdersFilter filter) => load(filter: filter);

  Future<void> clearFilter() => load(filter: const OrdersFilter());

  Future<bool> createOrder(CreateOrderRequest req) async {
    try {
      final response = await ApiClient.instance.post(
        '/pharmacy/orders',
        data: req.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      final orderData = (body['data'] ?? body) as Map<String, dynamic>;
      final order = PharmacyOrder.fromJson(orderData);
      state = state.copyWith(orders: [order, ...state.orders]);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['message'] as String? ?? 'Ошибка создания',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> confirmOrder(String token) async {
    try {
      await ApiClient.instance.put('/pharmacy/orders/$token/confirm');
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(String token) async {
    try {
      await ApiClient.instance.put('/pharmacy/orders/$token/cancel');
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>(
  (ref) => OrdersNotifier(),
);
