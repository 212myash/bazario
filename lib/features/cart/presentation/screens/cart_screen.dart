import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/cart_model.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(cartProvider.notifier).fetchCart();
      await ref.read(wishlistProvider.notifier).fetchWishlist();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(cartProvider.notifier).fetchCart(),
      ref.read(wishlistProvider.notifier).fetchWishlist(),
    ]);
  }

  String _money(double value) {
    return '\$${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final wishlistState = ref.watch(wishlistProvider);
    final cartItems = cartState.cart?.items ?? const <CartItemModel>[];
    final wishlistItems = wishlistState.items;
    final hasItems = cartItems.isNotEmpty;
    final total = cartState.cart?.total ?? 0;

    if (cartState.isLoading && cartState.cart == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          itemBuilder: (context, index) => const LoadingSkeleton(height: 128),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: 4,
        ),
      );
    }

    if (cartState.errorMessage != null && cartState.cart == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: ErrorStateView(
            message: cartState.errorMessage!,
            onRetry: _refresh,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CartHeader(count: cartItems.length),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ShippingAddressCard(
                        onEditTap: () =>
                            context.go('/profile/shipping-address'),
                      ),
                    ),
                  ),
                  if (hasItems)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverList.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final product = item.product;
                          final productId = product?.id ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CartItemRow(
                              item: item,
                              priceLabel: _money(item.priceSnapshot),
                              onTap: () {
                                if ((product?.slug ?? '').isNotEmpty) {
                                  context.push(
                                    '/home/product/${product!.slug}',
                                  );
                                }
                              },
                              onRemove: () {
                                if (productId.isNotEmpty) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .removeItem(productId);
                                }
                              },
                              onMinus: () {
                                if (productId.isNotEmpty && item.quantity > 1) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .updateItem(productId, item.quantity - 1);
                                }
                              },
                              onPlus: () {
                                if (productId.isNotEmpty) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .updateItem(productId, item.quantity + 1);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            height: 148,
                            width: 148,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F6F8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              size: 62,
                              color: Color(0xFF0B4DFF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'From Your Wishlist',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          letterSpacing: -0.8,
                          color: const Color(0xFF1D1F24),
                        ),
                      ),
                    ),
                  ),
                  if (wishlistState.isLoading && wishlistItems.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverList.builder(
                        itemCount: 2,
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LoadingSkeleton(height: 122),
                        ),
                      ),
                    )
                  else if (wishlistItems.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Text('No wishlist items yet.'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      sliver: SliverList.builder(
                        itemCount: wishlistItems.length,
                        itemBuilder: (context, index) {
                          final product = wishlistItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WishlistRow(
                              product: product,
                              priceLabel: _money(product.displayPrice),
                              onTap: () =>
                                  context.push('/home/product/${product.slug}'),
                              onRemove: () => ref
                                  .read(wishlistProvider.notifier)
                                  .remove(product.id),
                              onAddToCart: () async {
                                await ref
                                    .read(cartProvider.notifier)
                                    .addItem(product.id);
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart'),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CheckoutBar(
                  totalLabel: _money(total),
                  enabled: hasItems,
                  onCheckout: () => context.push('/checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Cart',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            color: const Color(0xFF1D1F24),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 34,
          width: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFDDE3F4),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ShippingAddressCard extends StatelessWidget {
  const _ShippingAddressCard({required this.onEditTap});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2128),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '26, Duong So 2, Thao Dien Ward, An Phu, District 2, Ho Chi Minh city',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3D4048),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF0B4DFF),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onEditTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                height: 42,
                width: 42,
                child: Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.priceLabel,
    required this.onTap,
    required this.onRemove,
    required this.onMinus,
    required this.onPlus,
  });

  final CartItemModel item;
  final String priceLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return SizedBox(
      height: 126,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 132,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (product?.images.isEmpty ?? true)
                          ? const ColoredBox(
                              color: Color(0xFFF0F1F4),
                              child: Icon(Icons.image_outlined),
                            )
                          : CachedNetworkImage(
                              imageUrl: product!.images.first,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const ColoredBox(
                                    color: Color(0xFFF0F1F4),
                                    child: Icon(Icons.image_outlined),
                                  ),
                            ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onRemove,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          height: 34,
                          width: 34,
                          child: Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFF6B88),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    product?.title ?? 'Unknown Product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.2,
                      color: Color(0xFF23262F),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pink, Size M',
                  style: TextStyle(fontSize: 17, color: Color(0xFF2D3038)),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 30,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B1D21),
                        ),
                      ),
                    ),
                    _CircleAction(icon: Icons.remove, onTap: onMinus),
                    const SizedBox(width: 8),
                    _QtyBox(value: item.quantity),
                    const SizedBox(width: 8),
                    _CircleAction(icon: Icons.add, onTap: onPlus),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistRow extends StatelessWidget {
  const _WishlistRow({
    required this.product,
    required this.priceLabel,
    required this.onTap,
    required this.onRemove,
    required this.onAddToCart,
  });

  final ProductModel product;
  final String priceLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 132,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.images.isEmpty
                          ? const ColoredBox(
                              color: Color(0xFFF0F1F4),
                              child: Icon(Icons.image_outlined),
                            )
                          : CachedNetworkImage(
                              imageUrl: product.images.first,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const ColoredBox(
                                    color: Color(0xFFF0F1F4),
                                    child: Icon(Icons.image_outlined),
                                  ),
                            ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onRemove,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          height: 34,
                          width: 34,
                          child: Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFF6B88),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.2,
                      color: Color(0xFF23262F),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  priceLabel,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B1D21),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Tag(label: product.category?.name ?? 'Pink'),
                    const SizedBox(width: 8),
                    const _Tag(label: 'M'),
                    const Spacer(),
                    GestureDetector(
                      onTap: onAddToCart,
                      child: const Icon(
                        Icons.add_shopping_cart_rounded,
                        color: Color(0xFF0B4DFF),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFF0B4DFF), width: 2.2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 32,
          width: 32,
          child: Icon(icon, size: 18, color: const Color(0xFF0B4DFF)),
        ),
      ),
    );
  }
}

class _QtyBox extends StatelessWidget {
  const _QtyBox({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFF232632),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44, maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, color: Color(0xFF232632)),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.totalLabel,
    required this.enabled,
    required this.onCheckout,
  });

  final String totalLabel;
  final bool enabled;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F4),
        boxShadow: [
          BoxShadow(
            color: Color(0x15000000),
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
                fontSize: 30,
                letterSpacing: -1.1,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B1D21),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 50,
            width: 138,
            child: FilledButton(
              onPressed: enabled ? onCheckout : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B4DFF),
                disabledBackgroundColor: const Color(0xFFE7E7E9),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF222222),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
