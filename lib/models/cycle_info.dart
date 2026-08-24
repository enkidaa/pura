enum CyclePhase { menstrual, follicular, ovulation, luteal }

class CycleInfo {
  const CycleInfo({
    required this.lastPeriodStart,
    required this.cycleDay,
    required this.avgCycleLength,
    required this.phase,
    required this.predictedNextStart,
  });

  final DateTime lastPeriodStart;
  final int cycleDay;
  final int avgCycleLength;
  final CyclePhase phase;
  final DateTime predictedNextStart;

  // Rough estimate from cycle day only — not a medical prediction, just
  // enough signal for the AI digest and a simple UI label.
  factory CycleInfo.fromStarts(List<DateTime> startsDescending) {
    final lastStart = startsDescending.first;
    final today = DateTime.now();
    final cycleDay = today.difference(DateTime(lastStart.year, lastStart.month, lastStart.day)).inDays + 1;

    int avgLength = 28;
    if (startsDescending.length >= 2) {
      final diffs = <int>[];
      for (var i = 0; i < startsDescending.length - 1; i++) {
        diffs.add(startsDescending[i].difference(startsDescending[i + 1]).inDays);
      }
      avgLength = (diffs.reduce((a, b) => a + b) / diffs.length).round();
    }

    final ovulationDay = avgLength - 14;
    final CyclePhase phase;
    if (cycleDay <= 5) {
      phase = CyclePhase.menstrual;
    } else if (cycleDay < ovulationDay - 1) {
      phase = CyclePhase.follicular;
    } else if (cycleDay <= ovulationDay + 1) {
      phase = CyclePhase.ovulation;
    } else {
      phase = CyclePhase.luteal;
    }

    return CycleInfo(
      lastPeriodStart: lastStart,
      cycleDay: cycleDay,
      avgCycleLength: avgLength,
      phase: phase,
      predictedNextStart: lastStart.add(Duration(days: avgLength)),
    );
  }
}

/// One row of cycle history: a completed cycle (start to the next start),
/// or the current/ongoing one (start to today, no end yet). Period length
/// and fertile-window placement are never measured — the app only ever
/// records a period *start* date, not when it ends — so both are explicit
/// estimates, kept clearly labeled as such wherever they're shown rather
/// than presented as tracked data.
class CycleHistoryEntry {
  const CycleHistoryEntry({
    required this.startDate,
    required this.endDateExclusive,
    required this.isCurrent,
    required this.estimatedPeriodLengthDays,
    required this.estimatedFertileWindowStartDay,
    required this.estimatedFertileWindowLengthDays,
  });

  final DateTime startDate;

  /// Exclusive — the next cycle's start date, or (for the current cycle)
  /// tomorrow, so [totalLengthDays] counts today inclusively.
  final DateTime endDateExclusive;
  final bool isCurrent;
  final int estimatedPeriodLengthDays;

  /// 1-indexed day-of-cycle the estimated fertile window starts on.
  final int estimatedFertileWindowStartDay;
  final int estimatedFertileWindowLengthDays;

  int get totalLengthDays => endDateExclusive.difference(startDate).inDays;

  /// No period-length data exists anywhere in this app (see class doc) —
  /// this is a commonly-cited population average (~3-7 days), not this
  /// user's own measured value.
  static const _estimatedPeriodLengthDays = 5;
  static const _fertileWindowLengthDays = 5;

  static List<CycleHistoryEntry> fromStartsDescending(List<DateTime> startsDescending) {
    if (startsDescending.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var avgLength = 28;
    if (startsDescending.length >= 2) {
      final diffs = <int>[];
      for (var i = 0; i < startsDescending.length - 1; i++) {
        diffs.add(startsDescending[i].difference(startsDescending[i + 1]).inDays);
      }
      avgLength = (diffs.reduce((a, b) => a + b) / diffs.length).round();
    }

    return List.generate(startsDescending.length, (i) {
      final start = startsDescending[i];
      final isCurrent = i == 0;
      final endExclusive = isCurrent ? today.add(const Duration(days: 1)) : startsDescending[i - 1];
      // The current cycle's own length isn't known yet — fall back to the
      // average of past cycles just to place a fertile-window estimate.
      final cycleLength = isCurrent ? avgLength : endExclusive.difference(start).inDays;

      final ovulationDay = cycleLength - 14;
      final fertileStart = (ovulationDay - _fertileWindowLengthDays + 1).clamp(1, cycleLength);
      final periodLength = _estimatedPeriodLengthDays.clamp(
        0,
        isCurrent ? cycleLength : endExclusive.difference(start).inDays,
      );

      return CycleHistoryEntry(
        startDate: start,
        endDateExclusive: endExclusive,
        isCurrent: isCurrent,
        estimatedPeriodLengthDays: periodLength,
        estimatedFertileWindowStartDay: fertileStart,
        estimatedFertileWindowLengthDays: _fertileWindowLengthDays,
      );
    });
  }
}
