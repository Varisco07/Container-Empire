import 'dart:ui';
import 'package:flutter/material.dart';

/// Pannello glassmorphism premium: blur di sfondo + vetro traslucido +
/// bordo neon sottile + glow opzionale. Base UI di tutte le card del Tycoon.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color tint;
  final Color borderColor;
  final Color? glow;
  final double glowBlur;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.blur = 18,
    this.tint = const Color(0x14FFFFFF),
    this.borderColor = const Color(0x33FFFFFF),
    this.glow,
    this.glowBlur = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow != null
            ? [
                BoxShadow(
                  color: glow!.withOpacity(0.35),
                  blurRadius: glowBlur,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint,
                  tint.withOpacity(0.02),
                ],
              ),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
