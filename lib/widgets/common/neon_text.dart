import 'package:flutter/material.dart';

class NeonText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final double blurRadius;

  const NeonText(
    this.text, {
    super.key,
    required this.color,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.blurRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        shadows: [
          Shadow(color: color.withOpacity(0.8), blurRadius: blurRadius),
          Shadow(color: color.withOpacity(0.4), blurRadius: blurRadius * 2),
        ],
      ),
    );
  }
}
