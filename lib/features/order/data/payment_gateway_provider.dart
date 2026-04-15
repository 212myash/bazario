import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'payment_gateway.dart';

final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  final gateway = RazorpayPaymentGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});
