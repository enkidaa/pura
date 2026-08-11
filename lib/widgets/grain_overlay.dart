import 'dart:math';
import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Faint static noise over the background — the "film grain" texture that
/// keeps a flat color from reading as flat. Opacity/blend come from
/// CircadianTokens so it rides the wake-to-night curve too. Painted once
/// and cached; ignores touches.
class GrainTexture extends StatelessWidget {
  const GrainTexture({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    return IgnorePointer(
      child: Opacity(
        opacity: tokens.grainOpacity,
        child: CustomPaint(
          painter: _GrainPainter(tokens.grainBlend),
          size: Size.infinite,
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter(this.blend);

  final BlendMode blend;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
    final paint = Paint()
      ..color = Colors.black
      ..blendMode = blend;
    const dotCount = 4000;
    for (var i = 0; i < dotCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => oldDelegate.blend != blend;
}
