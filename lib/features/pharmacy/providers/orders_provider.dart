import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrdersState {
  final List<PharmacyOrder> orders;
  final bool isLoading;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<PharmacyOrder>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier() : super(const OrdersState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get('/pharmacy/orders');
      final list = (response.data as List)
          .map((e) => PharmacyOrder.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(orders: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    }
  }

  Future<bool> createOrder(CreateOrderRequest req) async {
    try {
      final response = await ApiClient.instance.post(
        '/pharmacy/orders',
        data: req.toJson(),
      );
      final order = PharmacyOrder.fromJson(
          response.data as Map<String, dynamic>);
      state = state.copyWith(orders: [order, ...state.orders]);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['message'] as String? ?? 'Ошибка создания',
      );
      return false;
    }
  }

  Future<bool> confirmOrder(String token) async {
    try {
      await ApiClient.instance.put('/pharmacy/orders/$token/confirm');
      await load();
      return true;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(String token) async {
    try {
      await ApiClient.instance.put('/pharmacy/orders/$token/cancel');
      await load();
      return true;
    } on DioException catch (_) {
      return false;
    }
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>(
  (ref) => OrdersNotifier(),
);
