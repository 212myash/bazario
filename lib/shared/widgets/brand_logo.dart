import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.width = 180,
    this.showWordmark = true,
    this.fit = BoxFit.contain,
  });

  final double width;
  final bool showWordmark;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoPath = showWordmark
      ? (isDark ? 'assets/images/DarkLogo.png' : 'assets/images/LightLogo.png')
      : (isDark
          ? 'assets/images/Darckicon.png'
          : 'assets/images/Lighticon.png');

    return Image.asset(
      logoPath,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _FallbackBrand(width: width, showWordmark: showWordmark);
      },
    );
  }
}

class _FallbackBrand extends StatelessWidget {
  const _FallbackBrand({required this.width, required this.showWordmark});

  final double width;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconSize = showWordmark ? width * 0.22 : width * 0.72;

    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_checkout_rounded,
            size: iconSize,
            color: colorScheme.secondary,
          ),
          if (showWordmark) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'BAZARIO',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}