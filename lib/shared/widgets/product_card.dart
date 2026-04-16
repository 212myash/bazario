import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹');

    return Card(
      elevation: 4,
      shadowColor: const Color(0x15000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: product.images.isEmpty
                            ? ''
                            : product.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currency.format(product.displayPrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${product.ratingAverage} (${product.ratingCount})',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Spacer(),
                  _AddToCartButton(onPressed: onAddToCart),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatefulWidget {
  const _AddToCartButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  double _scale = 1;

  void _animateAndTrigger() {
    if (widget.onPressed == null) {
      return;
    }

    setState(() => _scale = 0.88);
    Future.delayed(const Duration(milliseconds: 90), () {
      if (!mounted) {
        return;
      }
      setState(() => _scale = 1);
      widget.onPressed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: _animateAndTrigger,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
