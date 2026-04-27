import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/client_model.dart';

class ClientsState {
  final List<PharmacyClient> clients;
  final bool isLoading;
  final String? error;

  const ClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
  });

  ClientsState copyWith({
    List<PharmacyClient>? clients,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ClientsState(
        clients: clients ?? this.clients,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class ClientsNotifier extends StateNotifier<ClientsState> {
  ClientsNotifier() : super(const ClientsState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get(
        '/pharmacy/clients',
        params: {if (search != null && search.isNotEmpty) 'search': search},
      );
      final list = (response.data as List)
          .map((e) => PharmacyClient.fromJson(e as Map<String, dynamic>))
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

final clientsProvider =
    StateNotifierProvider<ClientsNotifier, ClientsState>(
  (ref) => ClientsNotifier(),
);
