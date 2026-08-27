import '../l10n/app_strings.dart';

enum ScheduleType { daily, timesPerWeek, specificWeekdays, cyclic }

String scheduleTypeLabel(ScheduleType type, AppStrings strings) {
  switch (type) {
    case ScheduleType.daily:
      return strings.scheduleOgniGiorno;
    case ScheduleType.timesPerWeek:
      return strings.scheduleNVolteASettimana;
    case ScheduleType.specificWeekdays:
      return strings.scheduleGiorniSpecifici;
    case ScheduleType.cyclic:
      return strings.scheduleCiclico;
  }
}

/// Deterministic even spread of [timesPerWeek] occurrences across the
/// week (Mon=1..Sun=7) — a pure function of the count, so the same input
/// always produces the same days without needing to persist them.
Set<int> autoDistributeWeekdays(int timesPerWeek) {
  if (timesPerWeek <= 0) return {};
  if (timesPerWeek >= 7) return {1, 2, 3, 4, 5, 6, 7};
  final days = <int>{};
  for (var i = 0; i < timesPerWeek; i++) {
    days.add(1 + ((i * 7) ~/ timesPerWeek));
  }
  return days;
}

ScheduleType _typeFromDb(String? value) {
  switch (value) {
    case 'timesPerWeek':
      return ScheduleType.timesPerWeek;
    case 'specificWeekdays':
      return ScheduleType.specificWeekdays;
    case 'cyclic':
      return ScheduleType.cyclic;
    default:
      return ScheduleType.daily;
  }
}

/// Shared row <-> ScheduleSpec mapping for practice_routine and
/// supplement_routine, which carry identical scheduling columns.
ScheduleSpec scheduleFromRow(Map<String, dynamic> row) {
  final anchorStr = row['cycle_anchor'] as String?;
  return ScheduleSpec(
    type: _typeFromDb(row['schedule_type'] as String?),
    timesPerWeek: row['times_per_week'] as int?,
    weekdays: ((row['weekdays'] as List?)?.map((w) => w as int).toSet()) ?? const {},
    cycleOnDays: row['cycle_on_days'] as int?,
    cycleOffDays: row['cycle_off_days'] as int?,
    cycleAnchor: anchorStr == null ? null : DateTime.parse(anchorStr),
  );
}

Map<String, dynamic> scheduleToRow(ScheduleSpec spec) {
  return {
    'schedule_type': spec.type.name,
    'times_per_week': spec.timesPerWeek,
    'weekdays': spec.weekdays.isEmpty ? null : spec.weekdays.toList(),
    'cycle_on_days': spec.cycleOnDays,
    'cycle_off_days': spec.cycleOffDays,
    'cycle_anchor': spec.cycleAnchor == null
        ? null
        : '${spec.cycleAnchor!.year.toString().padLeft(4, '0')}-'
            '${spec.cycleAnchor!.month.toString().padLeft(2, '0')}-'
            '${spec.cycleAnchor!.day.toString().padLeft(2, '0')}',
  };
}

/// Programmazione dell'assunzione — separata dalla presenza in routine
/// (practice_routine/supplement_routine) e dai promemoria (notifiche).
/// Determina solo se una pratica/integratore è "previsto" in un dato giorno.
class ScheduleSpec {
  const ScheduleSpec({
    this.type = ScheduleType.daily,
    this.timesPerWeek,
    this.weekdays = const {},
    this.cycleOnDays,
    this.cycleOffDays,
    this.cycleAnchor,
  });

  final ScheduleType type;
  final int? timesPerWeek;

  /// Only meaningful for [ScheduleType.specificWeekdays] — for
  /// [ScheduleType.timesPerWeek] the days are always derived via
  /// [autoDistributeWeekdays].
  final Set<int> weekdays;
  final int? cycleOnDays;
  final int? cycleOffDays;
  final DateTime? cycleAnchor;

  bool isDueOn(DateTime date) {
    switch (type) {
      case ScheduleType.daily:
        return true;
      case ScheduleType.timesPerWeek:
        final n = timesPerWeek;
        if (n == null) return true;
        return autoDistributeWeekdays(n).contains(date.weekday);
      case ScheduleType.specificWeekdays:
        return weekdays.contains(date.weekday);
      case ScheduleType.cyclic:
        final anchor = cycleAnchor;
        final on = cycleOnDays;
        final off = cycleOffDays;
        if (anchor == null || on == null || off == null) return true;
        final period = on + off;
        if (period <= 0) return true;
        final daysSince = DateTime(date.year, date.month, date.day)
            .difference(DateTime(anchor.year, anchor.month, anchor.day))
            .inDays;
        final pos = daysSince % period;
        return (pos >= 0 ? pos : pos + period) < on;
    }
  }

  ScheduleSpec copyWith({
    ScheduleType? type,
    int? timesPerWeek,
    Set<int>? weekdays,
    int? cycleOnDays,
    int? cycleOffDays,
    DateTime? cycleAnchor,
  }) {
    return ScheduleSpec(
      type: type ?? this.type,
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
      weekdays: weekdays ?? this.weekdays,
      cycleOnDays: cycleOnDays ?? this.cycleOnDays,
      cycleOffDays: cycleOffDays ?? this.cycleOffDays,
      cycleAnchor: cycleAnchor ?? this.cycleAnchor,
    );
  }
}
