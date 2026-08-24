class SleepLog {
  const SleepLog({required this.bedtime, required this.wakeTime, this.source});

  final DateTime bedtime;
  final DateTime wakeTime;

  /// Which HealthKit source this came from (e.g. "Orologio", an Apple
  /// Watch's name) — null for a manually-entered log, which has no such
  /// concept. Surfaced in the UI so it's clear what the number is based on
  /// instead of a silent blend of every source that wrote sleep data.
  final String? source;

  Duration get duration => wakeTime.difference(bedtime);
}
