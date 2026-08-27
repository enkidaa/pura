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
/// center completion ring, styled like a small solar system: a thin
/// orbit path, a glowing center, quiet minimal planets. Tap opens the
/// step's detail screen; double-tap is a quick done/undo shortcut that
/// doesn't leave the orbit. Calm and quiet on purpose: no bounce on the
/// wheel itself — the only motion is the deliberate drag-to-rotate and the
/// bounded tap-scale on each planet, never a continuous/looping animation.
///
/// [outOfBudgetIds] marks steps that don't fit today's time budget — they
/// stay on the wheel at the same fixed spacing as everything else (branch
/// count never shrinks just because time is tight), just dimmed, and the
/// whole wheel can be dragged around to bring any of them into easy reach.
class RitualOrbit extends StatefulWidget {
  const RitualOrbit({
    super.key,
    required this.steps,
    required this.completedIds,
    required this.onToggle,
    required this.onOpenDetail,
    this.outOfBudgetIds = const {},
  });

  final List<RitualEntry> steps;
  final Set<String> completedIds;
  final Set<String> outOfBudgetIds;
  final ValueChanged<RitualEntry> onToggle;
  final ValueChanged<RitualEntry> onOpenDetail;

  @override
  State<RitualOrbit> createState() => _RitualOrbitState();
}

class _RitualOrbitState extends State<RitualOrbit> {
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    if (steps.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final doneCount = steps.where((s) => widget.completedIds.contains(s.id)).length;

    return Column(
      children: [
        SizedBox(
          width: 320,
          height: 320,
          child: GestureDetector(
            onPanUpdate: (details) {
              const radius = 122.0;
              setState(() => _rotation += details.delta.dx / radius);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orbit path — a thin static ring at the planets' own
                // radius, the visual thread that ties them to the center.
                Container(
                  width: 244,
                  height: 244,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.hairline, width: 1),
                  ),
                ),
                ...List.generate(steps.length, (i) {
                  final angle =
                      (i * (360 / steps.length) - 90) * math.pi / 180 + _rotation;
                  const radius = 122.0;
                  final entry = steps[i];
                  final on = widget.completedIds.contains(entry.id);
                  final outOfBudget = widget.outOfBudgetIds.contains(entry.id);
                  return Positioned(
                    left: 160 + radius * math.cos(angle) - 32,
                    top: 160 + radius * math.sin(angle) - 32,
                    child: Opacity(
                      opacity: outOfBudget ? 0.4 : 1.0,
                      child: _OrbitPlanet(
                        label: _shortLabels[entry.id] ?? entry.title.split(' ').first,
                        on: on,
                        onTap: () => widget.onOpenDetail(entry),
                        onDoubleTap: () => widget.onToggle(entry),
                      ),
                    ),
                  );
                }),
                // Center glow — a soft halo behind the ring, the wheel's
                // own quiet "star" rather than a flat panel.
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface.withValues(alpha: tokens.surfaceAlpha * 0.55),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.16),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: tokens.shadowColor,
                        blurRadius: tokens.shadowBlur * 0.5,
                        offset: Offset(0, tokens.shadowOffsetY * 0.3),
                      ),
                    ],
                  ),
                ),
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
        ),
        const SizedBox(height: 18),
        Text(
          strings.doppioTapSegna,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        if (widget.outOfBudgetIds.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            strings.ruotaPerVedereTutto,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// A single orbit "planet" — a flat, minimal disc with a thin rim, quiet
/// by default and lit by a soft outer glow (not a bright fill) once done.
/// No gradient body, no glossy highlight — restrained on purpose, so the
/// wheel reads as precise/futuristic rather than glassy. All static
/// shadows, no blur filter and no looping animation; the only motion is a
/// bounded scale-down on tap-press, released the moment the finger lifts.
class _OrbitPlanet extends StatefulWidget {
  const _OrbitPlanet({
    required this.label,
    required this.on,
    required this.onTap,
    required this.onDoubleTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  State<_OrbitPlanet> createState() => _OrbitPlanetState();
}

class _OrbitPlanetState extends State<_OrbitPlanet> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;

    final fill = widget.on
        ? tokens.accent2.withValues(alpha: 0.16)
        : scheme.surface.withValues(alpha: tokens.surfaceAlpha * 0.7);
    final rimColor = widget.on
        ? scheme.primary.withValues(alpha: 0.55)
        : scheme.outlineVariant.withValues(alpha: tokens.borderAlpha * 0.8);

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: rimColor, width: 1),
            boxShadow: [
              if (widget.on)
                BoxShadow(color: scheme.primary.withValues(alpha: 0.22), blurRadius: 16, spreadRadius: 0.5),
              BoxShadow(
                color: tokens.shadowColor,
                blurRadius: tokens.shadowBlur * 0.4,
                offset: Offset(0, tokens.shadowOffsetY * 0.3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: widget.on ? scheme.onSurfaceVariant : scheme.outline,
              ),
            ),
          ),
        ),
      ),
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
