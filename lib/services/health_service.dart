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
}
