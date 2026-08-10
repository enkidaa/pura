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
