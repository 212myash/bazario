import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/profile_api_service.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.user,
  });

  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final UserModel? user;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    UserModel? user,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
    );
  }
}

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService(ref.watch(dioProvider));
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier(ref.watch(profileApiServiceProvider));
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._api) : super(const ProfileState());

  final ProfileApiService _api;

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.getMyProfile();
      final user = UserModel.fromJson(
        (response['data'] ?? {}) as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, user: user, clearError: true);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to fetch profile',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch profile',
      );
    }
  }

  Future<bool> updateProfile({required String name, String? phone}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final response = await _api.updateProfile(name: name, phone: phone);
      final user = UserModel.fromJson(
        (response['data'] ?? {}) as Map<String, dynamic>,
      );
      state = state.copyWith(isSaving: false, user: user, clearError: true);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to update profile',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update profile',
      );
      return false;
    }
  }

  Future<void> addAddress(Map<String, dynamic> payload) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final response = await _api.addAddress(payload);
      final current = state.user;
      final addresses = (response['data'] as List<dynamic>? ?? [])
          .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (current != null) {
        state = state.copyWith(
          isSaving: false,
          user: current.copyWith(addresses: addresses),
          clearError: true,
        );
      } else {
        state = state.copyWith(isSaving: false, clearError: true);
      }
    } on DioException catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to add address',
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to add address',
      );
    }
  }

  Future<void> updateAddress(
    String addressId,
    Map<String, dynamic> payload,
  ) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final response = await _api.updateAddress(addressId, payload);
      final current = state.user;
      final addresses = (response['data'] as List<dynamic>? ?? [])
          .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (current != null) {
        state = state.copyWith(
          isSaving: false,
          user: current.copyWith(addresses: addresses),
          clearError: true,
        );
      } else {
        state = state.copyWith(isSaving: false, clearError: true);
      }
    } on DioException catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to update address',
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update address',
      );
    }
  }

  Future<void> deleteAddress(String addressId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final response = await _api.deleteAddress(addressId);
      final current = state.user;
      final addresses = (response['data'] as List<dynamic>? ?? [])
          .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (current != null) {
        state = state.copyWith(
          isSaving: false,
          user: current.copyWith(addresses: addresses),
          clearError: true,
        );
      } else {
        state = state.copyWith(isSaving: false, clearError: true);
      }
    } on DioException catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Failed to delete address',
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to delete address',
      );
    }
  }
}
