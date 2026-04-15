import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

final reviewProvider = Provider<ReviewService>((ref) {
  return ReviewService(ref.watch(dioProvider));
});

class ReviewService {
  ReviewService(this._dio);

  final Dio _dio;

  Future<void> submitReview({
    required String productId,
    required int rating,
    String? comment,
  }) async {
    await _dio.post(
      '/api/reviews/$productId',
      data: {'rating': rating, 'comment': comment},
    );
  }
}
