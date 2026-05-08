import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  int _shippingOptionIndex = 0;

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
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final cart = cartState.cart;
    final addresses = profileState.user?.addresses ?? [];
    final user = profileState.user;
    final selectedAddress =
        checkoutState.selectedAddress ??
        (addresses.where((item) => item.isDefault).isNotEmpty
            ? addresses.firstWhere((item) => item.isDefault)
            : (addresses.isNotEmpty ? addresses.first : null));

    if (selectedAddress != null && checkoutState.selectedAddress == null) {
      Future.microtask(
        () =>
            ref.read(checkoutProvider.notifier).selectAddress(selectedAddress),
      );
    }

    final isBusy = checkoutState.isProcessing;
    final canPay =
        cart != null &&
        cart.items.isNotEmpty &&
        selectedAddress != null &&
        !isBusy;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: cart == null || cart.items.isEmpty
          ? const EmptyStateView(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart is empty',
              subtitle: 'Add products to your cart before checkout.',
            )
          : SafeArea(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                    children: [
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1D1F24),
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        title: 'Shipping Address',
                        details: selectedAddress == null
                            ? 'No address added yet'
                            : '${selectedAddress.street}, ${selectedAddress.city}, ${selectedAddress.state}, ${selectedAddress.country}',
                        onEdit: () => context.push('/profile/shipping-address'),
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        title: 'Contact Information',
                        details:
                            '${selectedAddress?.phone ?? user?.phone ?? ''}\n${user?.email ?? ''}',
                        onEdit: () => context.push('/profile/edit'),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1D1F24),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 34,
                            width: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDDE3F4),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${cart.items.length}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0B4DFF),
                              side: const BorderSide(
                                color: Color(0xFF0B4DFF),
                                width: 1.8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Add Voucher',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...cart.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CheckoutItemRow(
                            title: item.product?.title ?? 'Product',
                            quantity: item.quantity,
                            lineTotal: currency.format(item.lineTotal),
                            imageUrl: item.product?.images.isNotEmpty == true
                                ? item.product!.images.first
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Shipping Options',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1D1F24),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ShippingOptionTile(
                        selected: _shippingOptionIndex == 0,
                        label: 'Standard',
                        daysLabel: '5-7 days',
                        priceLabel: 'FREE',
                        onTap: () => setState(() => _shippingOptionIndex = 0),
                      ),
                      const SizedBox(height: 8),
                      _ShippingOptionTile(
                        selected: _shippingOptionIndex == 1,
                        label: 'Express',
                        daysLabel: '1-2 days',
                        priceLabel: '\$12.00',
                        onTap: () => setState(() => _shippingOptionIndex = 1),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Delivered on or before Thursday, 23 April 2020',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF373A45),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1D1F24),
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          _PillIconButton(
                            icon: Icons.edit,
                            onTap: () => context.push('/profile/edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE2F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Card',
                          style: TextStyle(
                            color: Color(0xFF0B4DFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (checkoutState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          checkoutState.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _PayBar(
                      totalLabel: currency.format(cart.total),
                      isProcessing: isBusy,
                      enabled: canPay,
                      onPay: _startPayment,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.details,
    required this.onEdit,
  });

  final String title;
  final String details;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEF2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2129),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF2E323D),
                  ),
                ),
              ],
            ),
          ),
          _PillIconButton(icon: Icons.edit, onTap: onEdit),
        ],
      ),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  const _PillIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B4DFF),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _CheckoutItemRow extends StatelessWidget {
  const _CheckoutItemRow({
    required this.title,
    required this.quantity,
    required this.lineTotal,
    this.imageUrl,
  });

  final String title;
  final int quantity;
  final String lineTotal;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF656B7A),
                    )
                  : null,
            ),
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                height: 24,
                width: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDE3F4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              height: 1.2,
              color: Color(0xFF1F2128),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          lineTotal,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
            color: Color(0xFF1B1D21),
          ),
        ),
      ],
    );
  }
}

class _ShippingOptionTile extends StatelessWidget {
  const _ShippingOptionTile({
    required this.selected,
    required this.label,
    required this.daysLabel,
    required this.priceLabel,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final String daysLabel;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFDCE2F5) : const Color(0xFFEDEDEF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0B4DFF)
                      : const Color(0xFFDADBDD),
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1F27),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFF6F6F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        daysLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0B4DFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priceLabel,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: Color(0xFF1B1D21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.totalLabel,
    required this.enabled,
    required this.isProcessing,
    required this.onPay,
  });

  final String totalLabel;
  final bool enabled;
  final bool isProcessing;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F4),
        boxShadow: [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total $totalLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 32,
                letterSpacing: -1,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B1D21),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 136,
            height: 52,
            child: FilledButton(
              onPressed: enabled ? onPay : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF17181C),
                disabledBackgroundColor: const Color(0xFFB5B6BA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Pay',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
