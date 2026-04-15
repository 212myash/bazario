import 'package:dio/dio.dart';

class WishlistApiService {
  WishlistApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getWishlist() async {
    final response = await _dio.get('/api/wishlist');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addToWishlist(String productId) async {
    final response = await _dio.post(
      '/api/wishlist',
      data: {'productId': productId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeFromWishlist(String productId) async {
    final response = await _dio.delete('/api/wishlist/$productId');
    return response.data as Map<String, dynamic>;
  }
}
