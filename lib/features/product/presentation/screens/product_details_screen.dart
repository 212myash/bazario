import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/quantity_selector.dart';
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
    final currency = NumberFormat.currency(symbol: '?');

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
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

  final ProductModel product;
  final NumberFormat currency;

  @override
  ConsumerState<_ProductDetailsContent> createState() =>
      _ProductDetailsContentState();
}

class _ProductDetailsContentState
    extends ConsumerState<_ProductDetailsContent> {
  int _selectedRating = 5;
  int _selectedImageIndex = 0;
  int _selectedSizeIndex = 1;
  int _quantity = 1;
  bool _isSubmitting = false;
  final _commentController = TextEditingController();

  static const _sizes = ['S', 'M', 'L', 'XL'];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final images = product.images.isEmpty ? [''] : product.images;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Hero(
                tag: 'product-${product.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x17000000),
                        blurRadius: 22,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: images[_selectedImageIndex],
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = _selectedImageIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = index),
                      child: Container(
                        width: 62,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? BrandColors.logoViolet
                                : theme.colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                product.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    widget.currency.format(product.displayPrice),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BrandColors.logoGold,
                    ),
                  ),
                  const Spacer(),
                  QuantitySelector(
                    value: _quantity,
                    onDecrement: () {
                      if (_quantity <= 1) {
                        return;
                      }
                      setState(() => _quantity -= 1);
                    },
                    onIncrement: () => setState(() => _quantity += 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rating: ${product.ratingAverage} (${product.ratingCount} reviews)',
              ),
              const SizedBox(height: 16),
              Text(
                'Select Size',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_sizes.length, (index) {
                  final selected = index == _selectedSizeIndex;
                  return ChoiceChip(
                    label: Text(_sizes[index]),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) =>
                        setState(() => _selectedSizeIndex = index),
                    selectedColor: BrandColors.logoViolet,
                    backgroundColor: theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: selected
                            ? BrandColors.logoViolet
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(product.description),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text('Free Delivery'),
                  subtitle: const Text('Delivery in 3-5 working days'),
                  trailing: IconButton(
                    onPressed: () {
                      ref.read(wishlistProvider.notifier).add(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to wishlist')),
                      );
                    },
                    icon: const Icon(Icons.favorite_border),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Write a Review',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () =>
                        setState(() => _selectedRating = index + 1),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted')),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Ratings & Reviews',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (product.reviews.isEmpty)
                const Text(
                  'No reviews yet. Be the first to review this product.',
                )
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart. Proceed to checkout.'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.logoViolet,
                    ),
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
