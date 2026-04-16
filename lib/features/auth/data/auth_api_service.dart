import 'package:dio/dio.dart';

class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get('/api/users/me');
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/api/auth/logout');
  }
}
