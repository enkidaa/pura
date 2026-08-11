import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// The "Circadian Ambient Light" — a diffuse, barely-there glow behind the
/// content that drifts on a very slow cycle (never a fast/attention-
/// grabbing motion) and shifts color with the time-of-day tokens. It's
/// also what the frosted-glass cards (AppCard) actually refract; without
/// it, backdrop blur over a flat background looks like nothing happened.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 40))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p = reduceMotion ? 0.0 : _controller.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -120 + (reduceMotion ? 0 : 22 * math.sin(p)),
              right: -90 + (reduceMotion ? 0 : 18 * math.cos(p)),
              child: _Blob(color: scheme.primary, opacity: tokens.glowOpacity * 0.55, size: 340),
            ),
            Positioned(
              top: 260 + (reduceMotion ? 0 : 20 * math.cos(p * 0.8)),
              left: -140 + (reduceMotion ? 0 : 24 * math.sin(p * 0.8)),
              child: _Blob(color: tokens.accent2, opacity: tokens.glowOpacity * 0.5, size: 320),
            ),
            Positioned(
              bottom: -160 + (reduceMotion ? 0 : 18 * math.sin(p * 0.6)),
              right: -60 + (reduceMotion ? 0 : 20 * math.cos(p * 0.6)),
              child: _Blob(color: scheme.primary, opacity: tokens.glowOpacity * 0.4, size: 380),
            ),
          ],
        );
      },
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
