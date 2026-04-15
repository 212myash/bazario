import 'package:dio/dio.dart';

class CartApiService {
  CartApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getCart() async {
    final response = await _dio.get('/api/cart');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addItem(
    String productId, {
    int quantity = 1,
  }) async {
    final response = await _dio.post(
      '/api/cart/items',
      data: {'productId': productId, 'quantity': quantity},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateItem(
    String productId,
    int quantity,
  ) async {
    final response = await _dio.patch(
      '/api/cart/items',
      data: {'productId': productId, 'quantity': quantity},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeItem(String productId) async {
    final response = await _dio.delete('/api/cart/items/$productId');
    return response.data as Map<String, dynamic>;
  }
}
