import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/pharmacy_model.dart';

class PharmacyProfileState {
  final PharmacyProfile? profile;
  final bool isLoading;
  final String? error;

  const PharmacyProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  PharmacyProfileState copyWith({
    PharmacyProfile? profile,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      PharmacyProfileState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class PharmacyProfileNotifier extends StateNotifier<PharmacyProfileState> {
  PharmacyProfileNotifier() : super(const PharmacyProfileState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiClient.instance.get('/pharmacy/me');
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final profile = PharmacyProfile.fromJson(data);
      state = state.copyWith(profile: profile, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] as String? ?? 'Ошибка загрузки',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> update({String? name, String? phone, String? email}) async {
    try {
      final response = await ApiClient.instance.put(
        '/pharmacy/me',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final profile = PharmacyProfile.fromJson(data);
      state = state.copyWith(profile: profile);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final pharmacyProfileProvider =
    StateNotifierProvider<PharmacyProfileNotifier, PharmacyProfileState>(
  (ref) => PharmacyProfileNotifier(),
);
