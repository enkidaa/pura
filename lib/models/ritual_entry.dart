/// What kind of catalog item a [RitualEntry] wraps — the Ritual orbit
/// shows a single unified list, but each entry still needs to know where
/// to route on tap (a different detail screen per kind) and where its
/// real data lives.
enum RitualEntryKind { routineStep, practice, supplement }

/// A single item in today's Ritual — the fixed fasting/skincare/light
/// RoutineSteps, plus whichever Practices and Integratori the user has
/// added to their own routine and are due today per their own schedule.
/// Completion is tracked the same way for every kind: routine_completions
/// keyed by [id] (a plain text column, not tied to any one catalog —
/// same reuse pattern as routine_step_notes/sources).
class RitualEntry {
  const RitualEntry({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.kind,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final RitualEntryKind kind;
}

/// Best-effort minutes parsed from a Practice's free-text frequency string
/// (e.g. "Prima di dormire · 4 min" -> 4) — Practice has no structured
/// duration field. Falls back to a short, deliberately-modest default
/// rather than overstating how long an untimed practice takes.
int parsePracticeDurationMinutes(String frequency) {
  final match = RegExp(r'(\d+)\s*min').firstMatch(frequency);
  if (match == null) return 3;
  return int.parse(match.group(1)!);
}
