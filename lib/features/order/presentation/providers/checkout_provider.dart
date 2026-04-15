import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/checkout_api_service.dart';

class CheckoutState {
  const CheckoutState({
    this.isProcessing = false,
    this.errorMessage,
    this.selectedAddress,
    this.currentOrder,
  });

  final bool isProcessing;
  final String? errorMessage;
  final AddressModel? selectedAddress;
  final OrderModel? currentOrder;

  CheckoutState copyWith({
    bool? isProcessing,
    String? errorMessage,
    AddressModel? selectedAddress,
    OrderModel? currentOrder,
    bool clearError = false,
  }) {
    return CheckoutState(
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedAddress: selectedAddress ?? this.selectedAddress,
      currentOrder: currentOrder ?? this.currentOrder,
    );
  }
}

final checkoutApiServiceProvider = Provider<CheckoutApiService>((ref) {
  return CheckoutApiService(ref.watch(dioProvider));
});

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) {
    return CheckoutNotifier(ref.watch(checkoutApiServiceProvider));
  },
);

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this._api) : super(const CheckoutState());

  final CheckoutApiService _api;

  void selectAddress(AddressModel address) {
    state = state.copyWith(selectedAddress: address, clearError: true);
  }

  Future<OrderModel?> createPendingOrder() async {
    if (state.selectedAddress == null) {
      state = state.copyWith(errorMessage: 'Please select a delivery address');
      return null;
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final response = await _api.placeOrder(
        shippingAddress: state.selectedAddress!.toShippingJson(),
        paymentMethod: 'razorpay',
      );
      final order = OrderModel.fromJson(
        (response['data'] ?? {}) as Map<String, dynamic>,
      );
      state = state.copyWith(
        isProcessing: false,
        currentOrder: order,
        clearError: true,
      );
      return order;
    } catch (_) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to create order',
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> createRazorpayOrder(String orderId) async {
    try {
      final response = await _api.createRazorpayOrder(orderId);
      return (response['data'] ?? {}) as Map<String, dynamic>;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to initialize payment');
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      await _api.verifyRazorpay(
        orderId: orderId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Payment verification failed');
      return false;
    }
  }
}
