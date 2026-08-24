import 'package:health/health.dart';

import '../models/sleep_log.dart';

class HealthService {
  final _health = Health();

  Future<bool> requestAuthorization() async {
    const types = [HealthDataType.SLEEP_ASLEEP];
    return _health.requestAuthorization(types, permissions: const [HealthDataAccess.READ]);
  }

  Future<SleepLog?> fetchLastNightSleep() async {
    final now = DateTime.now();
    final since = now.subtract(const Duration(hours: 24));

    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.SLEEP_ASLEEP],
      startTime: since,
      endTime: now,
    );

    if (data.isEmpty) return null;

    // Sleep data in Salute is a blend of whatever wrote it — Apple Watch's
    // motion-based auto-detection, the Orologio app's deliberate Programma
    // sonno, or a third-party app. Blending every source's samples into one
    // min/max window means one noisy source (e.g. a Watch nap) can distort
    // the whole night. When Orologio's own data is present, prefer it alone
    // — it's the one source based on a schedule the user actually set, not
    // an inference. `sourceId` is the writing app's bundle id (stable
    // across device language, unlike the human-readable `sourceName`);
    // `com.apple.mobiletimer` is Orologio/Clock's.
    final clockSource = data.where(
      (d) => d.sourceId.toLowerCase().contains('mobiletimer'),
    ).toList();
    final chosen = clockSource.isNotEmpty ? clockSource : data;

    chosen.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    return SleepLog(
      bedtime: chosen.first.dateFrom,
      wakeTime: chosen.last.dateTo,
      source: chosen.first.sourceName,
    );
  }

  Future<bool> requestMenstrualAuthorization() async {
    const types = [HealthDataType.MENSTRUATION_FLOW];
    return _health.requestAuthorization(types, permissions: const [HealthDataAccess.READ]);
  }

  /// Reads MENSTRUATION_FLOW entries from Salute and collapses consecutive
  /// flow-days into period start dates (a start = a flow day with no flow
  /// recorded in the 2 days before it) — HealthKit records per-day flow,
  /// not period boundaries directly.
  Future<List<DateTime>> fetchMenstrualPeriodStarts({int lookbackDays = 240}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: lookbackDays));

    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.MENSTRUATION_FLOW],
      startTime: since,
      endTime: now,
    );

    if (data.isEmpty) return [];

    final flowDays = data
        .map((d) => DateTime(d.dateFrom.year, d.dateFrom.month, d.dateFrom.day))
        .toSet()
        .toList()
      ..sort();

    final starts = <DateTime>[];
    for (var i = 0; i < flowDays.length; i++) {
      if (i == 0 || flowDays[i].difference(flowDays[i - 1]).inDays > 2) {
        starts.add(flowDays[i]);
      }
    }
    return starts;
  }
}
