import 'package:flutter/material.dart';

import '../../core/utils/responsive_text.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  @override
  Widget build(BuildContext context) {
    final textSize = adaptiveFontSize(context, base: 16, min: 13, max: 20);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(fontSize: textSize),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: textSize),
        contentPadding: EdgeInsets.symmetric(
          horizontal: adaptiveFontSize(context, base: 15, min: 12, max: 18),
          vertical: adaptiveFontSize(context, base: 12, min: 10, max: 15),
        ),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(onPressed: onSuffixTap, icon: Icon(suffixIcon)),
      ),
    );
  }
}
