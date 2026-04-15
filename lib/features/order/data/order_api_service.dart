import 'package:dio/dio.dart';

class OrderApiService {
  OrderApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getMyOrders({
    required int page,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/api/orders/my',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await _dio.get('/api/orders/my/$orderId');
    return response.data as Map<String, dynamic>;
  }
}
