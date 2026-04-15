import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/token_storage.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/auth_api_service.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.errorMessage,
  });

  final UserModel? user;
  final bool isLoading;
  final bool isLoggedIn;
  final String? errorMessage;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(dioProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authApiServiceProvider),
    ref.watch(tokenStorageProvider),
  )..tryAutoLogin();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._tokenStorage) : super(const AuthState());

  final AuthApiService _api;
  final TokenStorage _tokenStorage;

  Future<void> tryAutoLogin() async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isLoggedIn: true);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _api.login(email: email, password: password);
      final payload = (data['data'] ?? {}) as Map<String, dynamic>;
      final token = payload['accessToken']?.toString() ?? '';

      if (token.isEmpty) {
        throw Exception('Access token missing in response');
      }

      await _tokenStorage.saveAccessToken(token);
      final user = payload['user'] is Map<String, dynamic>
          ? UserModel.fromJson(payload['user'] as Map<String, dynamic>)
          : null;

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: user,
        clearError: true,
      );
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage:
            error.response?.data?['message']?.toString() ?? 'Login failed',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: 'Login failed',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _api.register(
        name: name,
        email: email,
        password: password,
      );
      final payload = (data['data'] ?? {}) as Map<String, dynamic>;
      final token = payload['accessToken']?.toString() ?? '';

      if (token.isEmpty) {
        throw Exception('Access token missing in response');
      }

      await _tokenStorage.saveAccessToken(token);
      final user = payload['user'] is Map<String, dynamic>
          ? UserModel.fromJson(payload['user'] as Map<String, dynamic>)
          : null;

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: user,
        clearError: true,
      );
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage:
            error.response?.data?['message']?.toString() ??
            'Registration failed',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: 'Registration failed',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _api.logout();
    } catch (_) {
      // Ignore backend logout errors and clear local auth state anyway.
    }

    await _tokenStorage.clear();
    state = const AuthState(isLoggedIn: false, isLoading: false);
  }

  Future<void> forceLogoutLocal() async {
    await _tokenStorage.clear();
    state = const AuthState(isLoggedIn: false, isLoading: false);
  }
}
