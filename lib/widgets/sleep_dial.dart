import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'ios_time_picker_sheet.dart';

/// Duration from bedtime to wake, both plain times-of-day — always the
/// *forward* span from bedtime to wake, wrapping past midnight when wake's
/// minute-of-day is smaller (the normal case: bed 23:00, wake 07:00).
/// Doesn't need actual dates: this is time-of-day arithmetic, equivalent to
/// (and simpler than) computing calendar dates for both ends.
Duration sleepDurationFor(TimeOfDay bedtime, TimeOfDay wakeTime) {
  final bedMinutes = bedtime.hour * 60 + bedtime.minute;
  final wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
  final elapsed = wakeMinutes >= bedMinutes
      ? wakeMinutes - bedMinutes
      : (24 * 60 - bedMinutes) + wakeMinutes;
  return Duration(minutes: elapsed);
}

enum _DialHandle { bedtime, wake }

/// 24-hour circular dial with two draggable handles (bedtime, wake) joined
/// by an arc — the sleep-tracking equivalent of iOS's own "Edit wake up
/// time" dial, but built from this app's own glass/circadian tokens
/// (CircadianTokens/ColorScheme) rather than iOS's literal colors.
///
/// Dragging a handle snaps to 5-minute increments (steadier under a
/// fingertip than exact-minute precision). A tap on a handle (movement
/// below a small threshold, so it's distinguishable from an intentional
/// drag) opens the same precise Cupertino time-picker sheet used
/// elsewhere in the app, so an exact time is always reachable even if
/// dragging on the actual device turns out to be fiddly.
class SleepDial extends StatefulWidget {
  const SleepDial({
    super.key,
    required this.initialBedtime,
    required this.initialWakeTime,
    required this.onChanged,
    this.size = 280,
  });

  final TimeOfDay initialBedtime;
  final TimeOfDay initialWakeTime;
  final void Function(TimeOfDay bedtime, TimeOfDay wakeTime) onChanged;
  final double size;

  @override
  State<SleepDial> createState() => _SleepDialState();
}

class _SleepDialState extends State<SleepDial> {
  late TimeOfDay _bedtime = widget.initialBedtime;
  late TimeOfDay _wakeTime = widget.initialWakeTime;

  _DialHandle? _dragging;
  double _panDistance = 0;

  static const _tapDistanceThreshold = 10.0;
  static const _handleHitRadius = 28.0;

  double _angleFor(TimeOfDay t) => (t.hour * 60 + t.minute) / (24 * 60) * 2 * math.pi;

  TimeOfDay _timeForAngle(double angle) {
    final normalized = angle % (2 * math.pi);
    final totalMinutes = (normalized / (2 * math.pi)) * 24 * 60;
    final snapped = (totalMinutes / 5).round() * 5 % (24 * 60);
    return TimeOfDay(hour: snapped ~/ 60, minute: snapped % 60);
  }

  Offset _handlePosition(double angle, double radius, Offset center) {
    // angle=0 is straight up (midnight at the top, matching the reference
    // dial); angle increases clockwise.
    return Offset(center.dx + radius * math.sin(angle), center.dy - radius * math.cos(angle));
  }

  double _angleFromPointer(Offset local, Offset center) {
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;
    return angle;
  }

  void _handlePanStart(DragStartDetails details, Offset center, double handleRadius) {
    final bedPos = _handlePosition(_angleFor(_bedtime), handleRadius, center);
    final wakePos = _handlePosition(_angleFor(_wakeTime), handleRadius, center);
    final toBed = (details.localPosition - bedPos).distance;
    final toWake = (details.localPosition - wakePos).distance;

    if (toBed <= _handleHitRadius && toBed <= toWake) {
      _dragging = _DialHandle.bedtime;
    } else if (toWake <= _handleHitRadius) {
      _dragging = _DialHandle.wake;
    } else {
      _dragging = null;
    }
    _panDistance = 0;
  }

  void _handlePanUpdate(DragUpdateDetails details, Offset center) {
    if (_dragging == null) return;
    _panDistance += details.delta.distance;
    final angle = _angleFromPointer(details.localPosition, center);
    final time = _timeForAngle(angle);
    setState(() {
      if (_dragging == _DialHandle.bedtime) {
        _bedtime = time;
      } else {
        _wakeTime = time;
      }
    });
    widget.onChanged(_bedtime, _wakeTime);
  }

  Future<void> _handlePanEnd(DragEndDetails details) async {
    final dragged = _dragging;
    _dragging = null;
    if (dragged == null) return;
    if (_panDistance >= _tapDistanceThreshold) return; // was a real drag

    // Treated as a tap on the handle — open the precise picker as a
    // fallback for anyone who finds the drag too fiddly to land exactly.
    final isBedtime = dragged == _DialHandle.bedtime;
    final picked = await showIosTimePickerSheet(
      context: context,
      title: isBedtime ? 'A che ora sei andato a letto?' : 'A che ora ti sei svegliato?',
      initialTime: isBedtime ? _bedtime : _wakeTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isBedtime) {
        _bedtime = picked;
      } else {
        _wakeTime = picked;
      }
    });
    widget.onChanged(_bedtime, _wakeTime);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<CircadianTokens>()!;
    final center = Offset(widget.size / 2, widget.size / 2);
    final handleRadius = widget.size / 2 - 24;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanStart: (d) => _handlePanStart(d, center, handleRadius),
        onPanUpdate: (d) => _handlePanUpdate(d, center),
        onPanEnd: _handlePanEnd,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _SleepDialPainter(
                bedtimeAngle: _angleFor(_bedtime),
                wakeAngle: _angleFor(_wakeTime),
                trackColor: scheme.outlineVariant.withValues(alpha: tokens.borderAlpha),
                arcColor: scheme.primary,
                tickColor: scheme.outline.withValues(alpha: 0.5),
              ),
            ),
            Positioned(
              top: 10,
              child: Icon(Icons.bedtime_outlined, size: 16, color: scheme.outline),
            ),
            Positioned(
              bottom: 10,
              child: Icon(Icons.wb_sunny_outlined, size: 16, color: scheme.outline),
            ),
            _buildHandle(
              angle: _angleFor(_bedtime),
              radius: handleRadius,
              center: center,
              color: scheme.secondary,
              icon: Icons.bedtime_outlined,
            ),
            _buildHandle(
              angle: _angleFor(_wakeTime),
              radius: handleRadius,
              center: center,
              color: scheme.primary,
              icon: Icons.wb_sunny_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle({
    required double angle,
    required double radius,
    required Offset center,
    required Color color,
    required IconData icon,
  }) {
    final pos = _handlePosition(angle, radius, center);
    return Positioned(
      left: pos.dx - 18,
      top: pos.dy - 18,
      child: IgnorePointer(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
          ),
          child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }
}

class _SleepDialPainter extends CustomPainter {
  const _SleepDialPainter({
    required this.bedtimeAngle,
    required this.wakeAngle,
    required this.trackColor,
    required this.arcColor,
    required this.tickColor,
  });

  final double bedtimeAngle;
  final double wakeAngle;
  final Color trackColor;
  final Color arcColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 24;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, trackPaint);

    // Tick marks every hour, a touch longer every 6h — purely decorative
    // (no labels drawn into the canvas; the moon/sun icons carry the
    // day/night reference points instead, kept as real widgets so they
    // stay crisp and themeable).
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.5;
    for (var h = 0; h < 24; h++) {
      final angle = h / 24 * 2 * math.pi;
      final isMajor = h % 6 == 0;
      final outer = radius + 10;
      final inner = radius + (isMajor ? 2 : 5);
      final p1 = Offset(center.dx + inner * math.sin(angle), center.dy - inner * math.cos(angle));
      final p2 = Offset(center.dx + outer * math.sin(angle), center.dy - outer * math.cos(angle));
      canvas.drawLine(p1, p2, tickPaint..strokeWidth = isMajor ? 2 : 1);
    }

    // Sleep arc: always the *forward* sweep from bedtime to wake, through
    // midnight if numerically needed — matches sleepDurationFor's math, so
    // the drawn arc always represents the same span as the shown duration.
    final sweep = (wakeAngle - bedtimeAngle) % (2 * math.pi);
    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    // Canvas angles are measured from the positive x-axis; our angle=0 is
    // "up", so shift by -pi/2 to align the coordinate systems.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      bedtimeAngle - math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SleepDialPainter oldDelegate) {
    return oldDelegate.bedtimeAngle != bedtimeAngle ||
        oldDelegate.wakeAngle != wakeAngle ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.arcColor != arcColor;
  }
}

/// Bottom sheet wrapping [SleepDial] — same Cupertino-sheet family as
/// [showIosTimePickerSheet] (header with Annulla/title/Fatto), so the two
/// pickers in the app feel related. Returns null if cancelled.
Future<(TimeOfDay, TimeOfDay)?> showSleepDialSheet(
  BuildContext context, {
  required TimeOfDay initialBedtime,
  required TimeOfDay initialWakeTime,
}) {
  var bedtime = initialBedtime;
  var wakeTime = initialWakeTime;

  return showModalBottomSheet<(TimeOfDay, TimeOfDay)?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final theme = Theme.of(sheetContext);
          final duration = sleepDurationFor(bedtime, wakeTime);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Annulla'),
                      ),
                      Text('Sonno', style: theme.textTheme.titleMedium),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop((bedtime, wakeTime)),
                        child: const Text('Fatto'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SleepDial(
                    initialBedtime: bedtime,
                    initialWakeTime: wakeTime,
                    onChanged: (b, w) => setSheetState(() {
                      bedtime = b;
                      wakeTime = w;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trascina le due maniglie, o tocca per inserire l\'orario esatto.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
