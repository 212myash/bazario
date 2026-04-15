import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/product_provider.dart';
import '../providers/review_provider.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(productDetailsProvider(slug));
    final currency = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorStateView(
          message: 'Could not load product details',
          onRetry: () => ref.invalidate(productDetailsProvider(slug)),
        ),
        data: (product) =>
            _ProductDetailsContent(product: product, currency: currency),
      ),
    );
  }
}

class _ProductDetailsContent extends ConsumerStatefulWidget {
  const _ProductDetailsContent({required this.product, required this.currency});

  final dynamic product;
  final NumberFormat currency;

  @override
  ConsumerState<_ProductDetailsContent> createState() =>
      _ProductDetailsContentState();
}

class _ProductDetailsContentState
    extends ConsumerState<_ProductDetailsContent> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Hero(
          tag: 'product-${product.id}',
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: product.images.isEmpty ? '' : product.images.first,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          product.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          widget.currency.format(product.displayPrice),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Rating: ${product.ratingAverage} (${product.ratingCount} reviews)',
        ),
        const SizedBox(height: 14),
        Text(product.description),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Add to Cart',
                onPressed: () {
                  ref.read(cartProvider.notifier).addItem(product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: () {
                ref.read(wishlistProvider.notifier).add(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to wishlist')),
                );
              },
              icon: const Icon(Icons.favorite_border),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Write a Review',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (index) => IconButton(
              onPressed: () => setState(() => _selectedRating = index + 1),
              icon: Icon(
                index < _selectedRating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber,
              ),
            ),
          ),
        ),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Share your experience...',
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Submit Review',
          isLoading: _isSubmitting,
          onPressed: () async {
            setState(() => _isSubmitting = true);
            await ref
                .read(reviewProvider)
                .submitReview(
                  productId: product.id,
                  rating: _selectedRating,
                  comment: _commentController.text.trim(),
                );
            if (!context.mounted) {
              return;
            }
            setState(() => _isSubmitting = false);
            ref.invalidate(productDetailsProvider(product.slug));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Review submitted')));
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Ratings & Reviews',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (product.reviews.isEmpty)
          const Text('No reviews yet. Be the first to review this product.')
        else
          ...product.reviews.map(
            (review) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(review.comment),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
