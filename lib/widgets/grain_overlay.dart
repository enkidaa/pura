import 'dart:math';
import 'package:flutter/material.dart';

/// Faint static noise over the background — the "film grain" texture used
/// in 2026 UI to fake tactile depth without the cost of blurred shadows
/// everywhere. Painted once and cached; ignores touches.
class GrainTexture extends StatelessWidget {
  const GrainTexture({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.025,
        child: const CustomPaint(painter: _GrainPainter(), size: Size.infinite, isComplex: true, willChange: false),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
    final paint = Paint()..color = Colors.black;
    const dotCount = 4000;
    for (var i = 0; i < dotCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
