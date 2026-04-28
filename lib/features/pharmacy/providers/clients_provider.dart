import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/client_model.dart';

class ClientsFilter {
  final String? search;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? minOrders;

  const ClientsFilter({
    this.search,
    this.dateFrom,
    this.dateTo,
    this.minOrders,
  });

  bool get isActive =>
      (search != null && search!.isNotEmpty) ||
      dateFrom != null ||
      dateTo != null ||
      minOrders != null;

  ClientsFilter copyWith({
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minOrders,
    bool clearSearch = false,
    bool clearDates = false,
    bool clearMinOrders = false,
  }) =>
      ClientsFilter(
        search: clearSearch ? null : search ?? this.search,
        dateFrom: clearDates ? null : dateFrom ?? this.dateFrom,
        dateTo: clearDates ? null : dateTo ?? this.dateTo,
        minOrders: clearMinOrders ? null : minOrders ?? this.minOrders,
      );
}

class ClientsState {
  final List<PharmacyClient> clients;
  final bool isLoading;
  final String? error;
  final ClientsFilter filter;

  const ClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
    this.filter = const ClientsFilter(),
  });

  ClientsState copyWith({
    List<PharmacyClient>? clients,
    bool? isLoading,
    String? error,
    ClientsFilter? filter,
    bool clearError = false,
  }) =>
      ClientsState(
        clients: clients ?? this.clients,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        filter: filter ?? this.filter,
      );
}

class ClientsNotifier extends StateNotifier<ClientsState> {
  ClientsNotifier() : super(const ClientsState()) {
    load();
  }

  Future<void> load({ClientsFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, clearError: true, filter: f);
    try {
      final params = <String, dynamic>{};
      if (f.search != null && f.search!.isNotEmpty) params['search'] = f.search;
      if (f.dateFrom != null) {
        params['dateFrom'] = f.dateFrom!.toIso8601String().split('T')[0];
      }
      if (f.dateTo != null) {
        params['dateTo'] = f.dateTo!.toIso8601String().split('T')[0];
      }
      if (f.minOrders != null) params['minOrders'] = f.minOrders;

      final response = await ApiClient.instance.get(
        '/pharmacy/clients',
        params: params.isEmpty ? null : params,
      );
      final body = response.data as Map<String, dynamic>;
      final dataField = body['data'];
      final List rawList = dataField is List
          ? dataField
          : dataField is Map
              ? ((dataField['clients'] ?? dataField['items'] ?? []) as List)
              : [];
      final list = rawList
          .map((e) => PharmacyClient.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(clients: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilter(ClientsFilter filter) => load(filter: filter);
  Future<void> clearFilter() => load(filter: const ClientsFilter());
}

final clientsProvider = StateNotifierProvider<ClientsNotifier, ClientsState>(
  (ref) => ClientsNotifier(),
);
