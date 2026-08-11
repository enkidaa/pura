import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Frosted-glass panel — real backdrop blur + translucent tint + a hairline
/// light-catching edge, in the spirit of iOS's Liquid Glass. Reads its
/// alpha/shadow from CircadianTokens instead of hardcoding them, so it
/// rides the same wake-to-night curve as the rest of the UI. Needs
/// something with color behind it (see AmbientBackground) or the blur has
/// nothing to refract.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.gradient,
    this.blur = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Gradient? gradient;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    const radius = 26.0;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor,
            blurRadius: tokens.shadowBlur,
            offset: Offset(0, tokens.shadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? scheme.surface.withValues(alpha: tokens.surfaceAlpha) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: tokens.borderAlpha),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
