import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final double? width; // Make width optional
  final double? height; // Make height optional
  final Color? backgroundColor; // Optional background color
  final Color? textColor;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.label,
    this.width, // Default to null
    this.height, // Default to null
    this.backgroundColor, // Default to null
    this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity, // Use infinity if width is not provided
      height: height ?? 50, // Default height
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ??
              Theme.of(context).primaryColor, // Default to theme color
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
