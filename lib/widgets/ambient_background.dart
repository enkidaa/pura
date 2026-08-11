import 'package:flutter/material.dart';

/// Soft, blurred color blobs sitting behind the content — the thing the
/// frosted-glass cards (AppCard) actually refract. Without this, backdrop
/// blur over a flat background looks like nothing happened.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strength = isDark ? 0.55 : 0.85;

    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -90,
          child: _Blob(color: scheme.primary, opacity: 0.30 * strength, size: 340),
        ),
        Positioned(
          top: 260,
          left: -140,
          child: _Blob(color: scheme.secondary, opacity: 0.26 * strength, size: 320),
        ),
        Positioned(
          bottom: -160,
          right: -60,
          child: _Blob(color: scheme.primary, opacity: 0.20 * strength, size: 380),
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
