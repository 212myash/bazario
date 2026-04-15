import 'package:dio/dio.dart';

class ProfileApiService {
  ProfileApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _dio.get('/api/users/me');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
  }) async {
    final response = await _dio.patch(
      '/api/users/me',
      data: {'name': name, if ((phone ?? '').isNotEmpty) 'phone': phone},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> payload) async {
    final response = await _dio.post('/api/users/me/addresses', data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAddress(
    String addressId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch(
      '/api/users/me/addresses/$addressId',
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    final response = await _dio.delete('/api/users/me/addresses/$addressId');
    return response.data as Map<String, dynamic>;
  }
}
