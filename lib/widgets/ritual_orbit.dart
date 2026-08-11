import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/routine_step.dart';

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
/// center completion ring, replacing a plain checklist. Calm and quiet on
/// purpose: no bounce, only short fades on selection.
class RitualOrbit extends StatefulWidget {
  const RitualOrbit({super.key, required this.steps, required this.completedIds, required this.onToggle});

  final List<RoutineStep> steps;
  final Set<String> completedIds;
  final ValueChanged<RoutineStep> onToggle;

  @override
  State<RitualOrbit> createState() => _RitualOrbitState();
}

class _RitualOrbitState extends State<RitualOrbit> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    if (steps.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    final theme = Theme.of(context);
    final current = steps[_index % steps.length];
    final done = widget.completedIds.contains(current.id);
    final doneCount = steps.where((s) => widget.completedIds.contains(s.id)).length;

    return Column(
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...List.generate(steps.length, (i) {
                final angle = (i * (360 / steps.length) - 90) * math.pi / 180;
                const radius = 108.0;
                final active = i == _index;
                final on = widget.completedIds.contains(steps[i].id);
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  left: 140 + radius * math.cos(angle) - 27,
                  top: 140 + radius * math.sin(angle) - 27,
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? scheme.primary.withValues(alpha: 0.3)
                            : on
                                ? tokens.accent2.withValues(alpha: 0.22)
                                : scheme.surface.withValues(alpha: tokens.surfaceAlpha * 0.7),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(
                            alpha: active ? tokens.borderAlpha * 1.4 : tokens.borderAlpha * 0.8,
                          ),
                        ),
                      ),
                      child: Text(
                        _shortLabels[steps[i].id] ?? steps[i].title.split(' ').first,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: active ? scheme.onSurface : (on ? scheme.onSurfaceVariant : scheme.outline),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(
                width: 126,
                height: 126,
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
                        Text('COMPLETI', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(current.id),
            children: [
              Text(current.title.toUpperCase(), textAlign: TextAlign.center, style: theme.textTheme.labelMedium),
              const SizedBox(height: 10),
              Text('${current.durationMinutes} min', style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => widget.onToggle(current),
                style: done
                    ? FilledButton.styleFrom(
                        backgroundColor: tokens.accent2.withValues(alpha: 0.28),
                        foregroundColor: scheme.onSurface,
                      )
                    : null,
                child: Text(done ? 'Fatto' : 'Segna come fatto'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => setState(() => _index = (_index + 1) % steps.length),
              child: const Text('Avanti'),
            ),
          ],
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
