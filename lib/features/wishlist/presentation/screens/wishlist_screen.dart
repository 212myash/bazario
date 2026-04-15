import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.items.isEmpty) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.66,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) =>
                  const LoadingSkeleton(height: 220),
              itemCount: 6,
            );
          }

          if (state.errorMessage != null && state.items.isEmpty) {
            return ErrorStateView(
              message: state.errorMessage!,
              onRetry: () =>
                  ref.read(wishlistProvider.notifier).fetchWishlist(),
            );
          }

          if (state.items.isEmpty) {
            return const EmptyStateView(
              icon: Icons.favorite_outline,
              title: 'Your wishlist is empty',
              subtitle: 'Save items you like to buy them later.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.66,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = state.items[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: ProductCard(
                      product: item,
                      onTap: () => context.push('/home/product/${item.slug}'),
                      onAddToCart: () {
                        ref.read(cartProvider.notifier).addItem(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Moved to cart')),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      onPressed: () =>
                          ref.read(wishlistProvider.notifier).remove(item.id),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              );
            },
            itemCount: state.items.length,
          );
        },
      ),
    );
  }
}
