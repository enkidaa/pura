class FastingLog {
  const FastingLog({this.firstMealTime, this.lastMealTime});

  final DateTime? firstMealTime;
  final DateTime? lastMealTime;

  /// True when the most recently marked event was the first meal — i.e.
  /// still inside the eating window. False (fasting) when the last meal
  /// was marked more recently, or nothing has been logged at all yet.
  bool get isEating =>
      firstMealTime != null &&
      (lastMealTime == null || firstMealTime!.isAfter(lastMealTime!));

  /// When the current phase (eating or fasting) actually started — null
  /// only if nothing has ever been logged.
  DateTime? get currentPhaseStart => isEating ? firstMealTime : lastMealTime;
}
