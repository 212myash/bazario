import 'package:flutter/widgets.dart';

double adaptiveFontSize(
  BuildContext context, {
  required double base,
  double min = 12,
  double max = 36,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final widthScale = (width / 390).clamp(0.85, 1.15);
  final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(0.9, 1.35);
  final size = base * widthScale * textScale;
  return size.clamp(min, max).toDouble();
}
