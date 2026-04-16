import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colorScheme.secondary : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.secondary : const Color(0xFFE7EAF0),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.secondary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
