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

    data.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    return SleepLog(bedtime: data.first.dateFrom, wakeTime: data.last.dateTo);
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
