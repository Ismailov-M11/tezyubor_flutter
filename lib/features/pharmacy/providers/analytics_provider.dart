import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/analytics_model.dart';

class AnalyticsState {
  final PharmacyAnalytics? data;
  final bool isLoading;
  final String? error;

  const AnalyticsState({this.data, this.isLoading = false, this.error});

  AnalyticsState copyWith({
    PharmacyAnalytics? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AnalyticsState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(const AnalyticsState()) {
    load();
  }

  Future<void> load({String? from, String? to}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get(
        '/pharmacy/analytics',
        params: {
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final rawData = body['data'] ?? body;
      final Map<String, dynamic> analyticsData;
      if (rawData is List) {
        analyticsData = {'ordersByDay': rawData};
      } else if (rawData is Map) {
        analyticsData = Map<String, dynamic>.from(rawData);
      } else {
        analyticsData = {};
      }
      final analytics = PharmacyAnalytics.fromJson(analyticsData);
      state = state.copyWith(data: analytics, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(),
);
