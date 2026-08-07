class SleepLog {
  const SleepLog({required this.bedtime, required this.wakeTime});

  final DateTime bedtime;
  final DateTime wakeTime;

  Duration get duration => wakeTime.difference(bedtime);
}
