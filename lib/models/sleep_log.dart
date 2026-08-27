class SleepLog {
  const SleepLog({required this.bedtime, required this.wakeTime, this.source, this.sleepDate});

  final DateTime bedtime;
  final DateTime wakeTime;

  /// Which HealthKit source this came from (e.g. "Orologio", an Apple
  /// Watch's name) — null for a manually-entered log, which has no such
  /// concept. Surfaced in the UI so it's clear what the number is based on
  /// instead of a silent blend of every source that wrote sleep data.
  final String? source;

  /// The sleep_logs row's own date key ("YYYY-MM-DD") — null unless this
  /// log came straight from the database (loadLastNight/loadRecentSleepLogs).
  /// Needed to correct a past night: the upsert is keyed on this, not on
  /// "today", so editing an old row doesn't create a duplicate one.
  final String? sleepDate;

  Duration get duration => wakeTime.difference(bedtime);
}
