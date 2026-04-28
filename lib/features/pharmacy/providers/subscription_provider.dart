import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class SubscriptionState {
  final bool isExpired;
  final bool isPayLoading;
  final String? payError;
  final String? checkoutUrl;

  const SubscriptionState({
    this.isExpired = false,
    this.isPayLoading = false,
    this.payError,
    this.checkoutUrl,
  });

  SubscriptionState copyWith({
    bool? isExpired,
    bool? isPayLoading,
    String? payError,
    String? checkoutUrl,
    bool clearError = false,
    bool clearUrl = false,
  }) =>
      SubscriptionState(
        isExpired: isExpired ?? this.isExpired,
        isPayLoading: isPayLoading ?? this.isPayLoading,
        payError: clearError ? null : payError ?? this.payError,
        checkoutUrl: clearUrl ? null : checkoutUrl ?? this.checkoutUrl,
      );
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  void checkExpiry(String? subscriptionExpiry) {
    if (subscriptionExpiry == null) {
      state = state.copyWith(isExpired: false);
      return;
    }
    try {
      final expiry = DateTime.parse(subscriptionExpiry);
      state = state.copyWith(isExpired: expiry.isBefore(DateTime.now()));
    } catch (_) {
      state = state.copyWith(isExpired: false);
    }
  }

  Future<String?> createPayment() async {
    state = state.copyWith(isPayLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.post('/pharmacy/subscription/pay');
      final body = response.data as Map<String, dynamic>;
      final url = (body['data'] as Map<String, dynamic>)['checkoutUrl'] as String?;
      state = state.copyWith(isPayLoading: false, checkoutUrl: url);
      return url;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Ошибка';
      state = state.copyWith(isPayLoading: false, payError: msg);
      return null;
    } catch (e) {
      state = state.copyWith(isPayLoading: false, payError: e.toString());
      return null;
    }
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(),
);
