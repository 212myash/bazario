import 'package:dio/dio.dart';

class ProductApiService {
  ProductApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 12,
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};

    if ((search ?? '').isNotEmpty) {
      queryParameters['search'] = search;
    }
    if ((category ?? '').isNotEmpty) {
      queryParameters['category'] = category;
    }
    if (minPrice != null) {
      queryParameters['minPrice'] = minPrice;
    }
    if (maxPrice != null) {
      queryParameters['maxPrice'] = maxPrice;
    }

    final response = await _dio.get(
      '/api/products',
      queryParameters: queryParameters,
    );

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProductDetails(String slug) async {
    final response = await _dio.get('/api/products/$slug');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCategories() async {
    final response = await _dio.get('/api/categories');
    return response.data as Map<String, dynamic>;
  }
}
