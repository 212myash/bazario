import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentSuccessPayload {
  const PaymentSuccessPayload({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

class PaymentFailurePayload {
  const PaymentFailurePayload({required this.code, required this.message});

  final int code;
  final String message;
}

class ExternalWalletPayload {
  const ExternalWalletPayload({required this.walletName});

  final String walletName;
}

abstract class PaymentGateway {
  void open({
    required Map<String, dynamic> options,
    required void Function(PaymentSuccessPayload response) onSuccess,
    required void Function(PaymentFailurePayload response) onError,
    required void Function(ExternalWalletPayload response) onExternalWallet,
  });

  void dispose();
}

class RazorpayPaymentGateway implements PaymentGateway {
  RazorpayPaymentGateway() {
    _razorpay = Razorpay();
  }

  late final Razorpay _razorpay;

  @override
  void open({
    required Map<String, dynamic> options,
    required void Function(PaymentSuccessPayload response) onSuccess,
    required void Function(PaymentFailurePayload response) onError,
    required void Function(ExternalWalletPayload response) onExternalWallet,
  }) {
    _razorpay.clear();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      onSuccess(
        PaymentSuccessPayload(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId ?? '',
          signature: response.signature ?? '',
        ),
      );
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      onError(
        PaymentFailurePayload(
          code: response.code ?? -1,
          message: response.message ?? 'Payment failed',
        ),
      );
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      onExternalWallet(
        ExternalWalletPayload(walletName: response.walletName ?? 'Unknown'),
      );
    });
    _razorpay.open(options);
  }

  @override
  void dispose() {
    _razorpay.clear();
  }
}
