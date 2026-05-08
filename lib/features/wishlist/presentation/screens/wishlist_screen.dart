import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/product_model.dart';
import '../../../../shared/services/recently_viewed_store.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(wishlistProvider.notifier).fetchWishlist());
  }

  String _userKey() {
    final user = ref.read(authProvider).user;
    if (user == null) {
      return 'guest';
    }
    if (user.id.trim().isNotEmpty) {
      return user.id.trim();
    }
    return user.email.trim().isNotEmpty ? user.email.trim() : 'guest';
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(wishlistProvider.notifier).fetchWishlist(),
      ref.read(productProvider.notifier).fetchProducts(refresh: true),
    ]);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistProvider);
    final productState = ref.watch(productProvider);
    final popularProducts = productState.products.take(8).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Wishlist',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1D1D1F),
                      letterSpacing: -1.1,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<List<RecentlyViewedItem>>(
                    future: RecentlyViewedStore.load(_userKey()),
                    builder: (context, snapshot) {
                      final items =
                          snapshot.data ?? const <RecentlyViewedItem>[];
                      if (items.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Recently viewed',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF222428),
                                      ),
                                ),
                              ),
                              Material(
                                color: const Color(0xFF0B4DFF),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: () {
                                    if (items.isNotEmpty) {
                                      context.push(
                                        '/home/product/${items.first.slug}',
                                      );
                                    }
                                  },
                                  customBorder: const CircleBorder(),
                                  child: const SizedBox(
                                    height: 42,
                                    width: 42,
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return _RecentAvatar(
                                  item: item,
                                  onTap: () => context.push(
                                    '/home/product/${item.slug}',
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (state.isLoading && state.items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  sliver: SliverList.builder(
                    itemCount: 4,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: LoadingSkeleton(height: 132),
                    ),
                  ),
                )
              else if (state.errorMessage != null && state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                    child: ErrorStateView(
                      message: state.errorMessage!,
                      onRetry: () =>
                          ref.read(wishlistProvider.notifier).fetchWishlist(),
                    ),
                  ),
                )
              else if (state.items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 22),
                        const Center(child: _EmptyWishlistBadge()),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Most Popular',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.2,
                                      color: const Color(0xFF222428),
                                    ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => context.go('/home'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1F2937),
                              ),
                              iconAlignment: IconAlignment.end,
                              label: const Text(
                                'See All',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              icon: Container(
                                height: 36,
                                width: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0B4DFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 196,
                          child: popularProducts.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No products available right now.',
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: popularProducts.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final product = popularProducts[index];
                                    return _PopularProductCard(
                                      product: product,
                                      onTap: () => context.push(
                                        '/home/product/${product.slug}',
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  sliver: SliverList.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _WishlistListItem(
                          item: item,
                          onTap: () =>
                              context.push('/home/product/${item.slug}'),
                          onRemove: () => ref
                              .read(wishlistProvider.notifier)
                              .remove(item.id),
                          onAddToCart: () async {
                            await ref
                                .read(cartProvider.notifier)
                                .addItem(item.id);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentAvatar extends StatelessWidget {
  const _RecentAvatar({required this.item, required this.onTap});

  final RecentlyViewedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66,
        width: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDDE2EA), width: 2.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: item.imageUrl.isEmpty
            ? const ColoredBox(
                color: Color(0xFFF2F4F8),
                child: Icon(Icons.image_outlined, color: Color(0xFF7C8798)),
              )
            : CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const ColoredBox(
                  color: Color(0xFFF2F4F8),
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

class _WishlistListItem extends StatelessWidget {
  const _WishlistListItem({
    required this.item,
    required this.onTap,
    required this.onRemove,
    required this.onAddToCart,
  });

  final ProductModel item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              height: 142,
              width: 136,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: item.images.isEmpty
                          ? const ColoredBox(
                              color: Color(0xFFF0F1F4),
                              child: Icon(Icons.image_outlined),
                            )
                          : CachedNetworkImage(
                              imageUrl: item.images.first,
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
                          height: 36,
                          width: 36,
                          child: Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFF4D79),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2A2A2D),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '\$${item.displayPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    letterSpacing: -0.8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1D21),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TagPill(
                      label: item.category?.name.isNotEmpty == true
                          ? item.category!.name
                          : 'Item',
                    ),
                    const SizedBox(width: 8),
                    const _TagPill(label: 'M'),
                    const Spacer(),
                    GestureDetector(
                      onTap: onAddToCart,
                      child: const Icon(
                        Icons.add_shopping_cart_rounded,
                        color: Color(0xFF0B4DFF),
                        size: 34,
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

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF232632),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyWishlistBadge extends StatelessWidget {
  const _EmptyWishlistBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 146,
      width: 146,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8FA),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite_border_rounded,
        size: 58,
        color: Color(0xFF0B4DFF),
      ),
    );
  }
}

class _PopularProductCard extends StatelessWidget {
  const _PopularProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 146,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: product.images.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFF1F3F7),
                        child: Icon(Icons.image_outlined),
                      )
                    : CachedNetworkImage(
                        imageUrl: product.images.first,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const ColoredBox(
                          color: Color(0xFFF1F3F7),
                          child: Icon(Icons.image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.ratingCount.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.favorite, color: Color(0xFF0B4DFF), size: 18),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: Color(0xFF3A3D45)),
            ),
          ],
        ),
      ),
    );
  }
}
