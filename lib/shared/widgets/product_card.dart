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
    final currency = NumberFormat.currency(symbol: '₹');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: product.images.isEmpty
                        ? ''
                        : product.images.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                currency.format(product.displayPrice),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${product.ratingAverage} (${product.ratingCount})'),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
