import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.height = 110});

  final double height;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade300;
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
