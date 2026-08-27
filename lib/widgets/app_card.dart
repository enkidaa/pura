import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Translucent panel with a hairline light-catching edge. Reads its
/// alpha/shadow from CircadianTokens so it rides the same wake-to-night
/// curve as the rest of the UI.
///
/// Used to be real BackdropFilter blur (frosted glass) — dropped entirely.
/// BackdropFilter forces a GPU re-sample of whatever's behind it on every
/// frame the backdrop changes (any scroll, any animation anywhere in the
/// same layer), and this widget is used dozens of times per screen. With
/// that many instances it made the whole app feel mechanical/laggy even
/// after cutting most instances down — removing it outright is what
/// actually fixed it. [blur] is kept as a no-op parameter so existing call
/// sites don't need touching.
///
/// The depth cue is restrained on purpose: a gradient rim (brighter along
/// the top, like an edge catching light from above) plus a two-layer
/// shadow (a tight contact shadow and a softer ambient one). No corner
/// sheen, no glossy highlights — those read as a glass bubble, not the
/// precise/quiet feel this app wants. All static gradients/shadows, no
/// blur, no animation — costs nothing extra per frame over a flat card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.gradient,
    this.blur = 0,
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

    final rimColor = scheme.outlineVariant;
    final rimAlpha = tokens.borderAlpha;

    // RepaintBoundary: this card is almost always one of several siblings
    // in a scrolling list. Without its own layer, every card repaints
    // whenever any one of them does (Flutter repaints per-layer, not
    // per-widget) — isolating each card keeps a scroll frame's repaint
    // cost limited to whichever cards actually changed.
    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            // Tight contact shadow — grounds the card against the surface
            // right beneath it.
            BoxShadow(
              color: tokens.shadowColor,
              blurRadius: tokens.shadowBlur * 0.35,
              offset: Offset(0, tokens.shadowOffsetY * 0.3),
            ),
            // Original soft ambient shadow — further and more diffuse.
            BoxShadow(
              color: tokens.shadowColor,
              blurRadius: tokens.shadowBlur,
              offset: Offset(0, tokens.shadowOffsetY),
            ),
          ],
        ),
        // A slim gradient rim (brighter along the top, fading toward the
        // bottom) is the only "edge catching light" cue — kept subtle.
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                rimColor.withValues(alpha: (rimAlpha * 1.6).clamp(0.0, 1.0)),
                rimColor.withValues(alpha: rimAlpha * 0.5),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 1),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: gradient == null ? scheme.surface.withValues(alpha: tokens.surfaceAlpha) : null,
                gradient: gradient,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
