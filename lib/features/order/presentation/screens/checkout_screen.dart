import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/payment_gateway.dart';
import '../../data/payment_gateway_provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _activeOrderId;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(cartProvider.notifier).fetchCart();
      ref.read(profileProvider.notifier).fetchProfile();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startPayment() async {
    final checkout = ref.read(checkoutProvider.notifier);
    final order = await checkout.createPendingOrder();
    if (order == null) return;

    _activeOrderId = order.id;
    final paymentData = await checkout.createRazorpayOrder(order.id);
    if (paymentData == null) return;

    final rzpOrder =
        (paymentData['razorpayOrder'] ?? {}) as Map<String, dynamic>;
    final keyId = paymentData['keyId']?.toString() ?? '';

    final options = {
      'key': keyId,
      'amount': rzpOrder['amount'],
      'name': 'Bazario',
      'order_id': rzpOrder['id'],
      'description': 'Order Payment',
      'prefill': {
        'name': ref.read(profileProvider).user?.name,
        'contact': ref.read(checkoutProvider).selectedAddress?.phone,
        'email': ref.read(profileProvider).user?.email,
      },
      'theme': {'color': '#0F766E'},
    };

    ref
        .read(paymentGatewayProvider)
        .open(
          options: options,
          onSuccess: _onPaymentSuccess,
          onError: _onPaymentError,
          onExternalWallet: _onExternalWallet,
        );
  }

  Future<void> _onPaymentSuccess(PaymentSuccessPayload response) async {
    final orderId = _activeOrderId;
    if (orderId == null) return;

    final isVerified = await ref
        .read(checkoutProvider.notifier)
        .verifyPayment(
          orderId: orderId,
          razorpayOrderId: response.orderId,
          razorpayPaymentId: response.paymentId,
          razorpaySignature: response.signature,
        );

    if (!mounted) return;

    if (isVerified) {
      ref.read(orderProvider.notifier).fetchOrders(refresh: true);
      ref.read(cartProvider.notifier).fetchCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful and order confirmed.'),
        ),
      );
      context.go('/orders');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment verification failed.')),
      );
    }
  }

  void _onPaymentError(PaymentFailurePayload response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _onExternalWallet(ExternalWalletPayload response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final profileState = ref.watch(profileProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final currency = NumberFormat.currency(symbol: '₹');

    final cart = cartState.cart;
    final addresses = profileState.user?.addresses ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart == null || cart.items.isEmpty
          ? const EmptyStateView(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart is empty',
              subtitle: 'Add products to your cart before checkout.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Select Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (addresses.isEmpty)
                  const EmptyStateView(
                    icon: Icons.location_on_outlined,
                    title: 'No Address Found',
                    subtitle:
                        'Please add an address in Profile before placing order.',
                  )
                else
                  ...addresses.map((address) {
                    final isSelected =
                        checkoutState.selectedAddress?.id == address.id;
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => ref
                            .read(checkoutProvider.notifier)
                            .selectAddress(address),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(address.fullName),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${address.shortAddress}\n${address.phone}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...cart.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.product?.title ?? 'Product'),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text(currency.format(item.lineTotal)),
                  ),
                ),
                const Divider(height: 26),
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      currency.format(cart.total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (checkoutState.errorMessage != null)
                  Text(
                    checkoutState.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Pay with Razorpay',
                  isLoading: checkoutState.isProcessing,
                  onPressed: addresses.isEmpty ? null : _startPayment,
                ),
              ],
            ),
    );
  }
}
