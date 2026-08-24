import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// The "Circadian Ambient Light" — a diffuse, barely-there glow behind the
/// content, positioned from the time of day rather than a running
/// animation. It's also what the frosted-glass cards (AppCard) actually
/// refract; without it, backdrop blur over a flat background looks like
/// nothing happened.
///
/// This used to drift continuously via a 40s AnimationController — looked
/// nice, but every AppCard's BackdropFilter had to re-sample the backdrop
/// on every single frame (the layer behind it never stopped changing),
/// which cost real perf on every screen in the app since AppCard is used
/// everywhere. Deriving the position from minute-of-day instead means it
/// only shifts when the screen naturally rebuilds (navigation, the 15-min
/// clock tick in PuraApp) — same slow-drift spirit, none of the per-frame
/// blur cost.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    final now = DateTime.now();
    final p = (now.hour * 60 + now.minute) / (24 * 60) * 2 * math.pi;

    return Stack(
      children: [
        Positioned(
          top: -120 + 22 * math.sin(p),
          right: -90 + 18 * math.cos(p),
          child: _Blob(color: scheme.primary, opacity: tokens.glowOpacity * 0.55, size: 340),
        ),
        Positioned(
          top: 260 + 20 * math.cos(p * 0.8),
          left: -140 + 24 * math.sin(p * 0.8),
          child: _Blob(color: tokens.accent2, opacity: tokens.glowOpacity * 0.5, size: 320),
        ),
        Positioned(
          bottom: -160 + 18 * math.sin(p * 0.6),
          right: -60 + 20 * math.cos(p * 0.6),
          child: _Blob(color: scheme.primary, opacity: tokens.glowOpacity * 0.4, size: 380),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.opacity, required this.size});

  final Color color;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
