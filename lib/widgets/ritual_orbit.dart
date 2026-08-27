import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../l10n/app_strings.dart';
import '../models/ritual_entry.dart';

const _shortLabels = {
  'sunlight': 'Luce',
  'lymphatic_drainage': 'Viso',
  'salt_water': 'Acqua',
  'cold_rinse': 'Freddo',
  'double_cleansing': 'Detersione',
  'targeted_serum': 'Siero',
  'retinoid': 'Retinoide',
};

/// The "Ritual" — a circular pick of the day's routine steps around a
/// center completion ring, replacing a plain checklist. Tap opens the
/// step's detail screen; double-tap is a quick done/undo shortcut that
/// doesn't leave the orbit. Calm and quiet on purpose: no bounce.
class RitualOrbit extends StatelessWidget {
  const RitualOrbit({
    super.key,
    required this.steps,
    required this.completedIds,
    required this.onToggle,
    required this.onOpenDetail,
  });

  final List<RitualEntry> steps;
  final Set<String> completedIds;
  final ValueChanged<RitualEntry> onToggle;
  final ValueChanged<RitualEntry> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final doneCount = steps.where((s) => completedIds.contains(s.id)).length;

    return Column(
      children: [
        SizedBox(
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...List.generate(steps.length, (i) {
                final angle = (i * (360 / steps.length) - 90) * math.pi / 180;
                const radius = 122.0;
                final on = completedIds.contains(steps[i].id);
                return Positioned(
                  left: 160 + radius * math.cos(angle) - 35,
                  top: 160 + radius * math.sin(angle) - 35,
                  child: GestureDetector(
                    onTap: () => onOpenDetail(steps[i]),
                    onDoubleTap: () => onToggle(steps[i]),
                    child: Container(
                      width: 70,
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on
                            ? tokens.accent2.withValues(alpha: 0.22)
                            : scheme.surface.withValues(alpha: tokens.surfaceAlpha * 0.7),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: tokens.borderAlpha * 0.8),
                        ),
                      ),
                      child: Text(
                        _shortLabels[steps[i].id] ?? steps[i].title.split(' ').first,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: on ? scheme.onSurfaceVariant : scheme.outline,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: doneCount / steps.length,
                    track: tokens.hairline,
                    arc: scheme.primary.withValues(alpha: 0.85),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.headlineMedium,
                            children: [
                              TextSpan(text: '$doneCount'),
                              TextSpan(
                                text: '/${steps.length}',
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(fontSize: 15, color: scheme.outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(strings.completi, style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          strings.doppioTapSegna,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.track, required this.arc});

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..color = arc
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.track != track || oldDelegate.arc != arc;
  }
}
