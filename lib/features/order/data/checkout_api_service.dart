import 'package:dio/dio.dart';

class CheckoutApiService {
  CheckoutApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> placeOrder({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
  }) async {
    final response = await _dio.post(
      '/api/orders',
      data: {
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRazorpayOrder(String orderId) async {
    final response = await _dio.post(
      '/api/payments/razorpay/order',
      data: {'orderId': orderId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyRazorpay({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _dio.post(
      '/api/payments/razorpay/verify',
      data: {
        'orderId': orderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
