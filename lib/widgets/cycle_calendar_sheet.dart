import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Calendar range picker for retroactively logging a past period: tap a
/// start day, tap an end day (or just the same day again for a 1-day
/// period), "Fatto" to confirm. Returns (startDate, lengthInDays) or null
/// if cancelled. This is a range picker, not Salute's per-day toggle —
/// simpler, and it maps directly onto what this app can actually store
/// (a start date + a length), rather than an arbitrary set of days.
Future<(DateTime, int)?> showCycleCalendarSheet(BuildContext context) {
  return showModalBottomSheet<(DateTime, int)?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => const _CycleCalendarSheetBody(),
  );
}

class _CycleCalendarSheetBody extends StatefulWidget {
  const _CycleCalendarSheetBody();

  @override
  State<_CycleCalendarSheetBody> createState() => _CycleCalendarSheetBodyState();
}

class _CycleCalendarSheetBodyState extends State<_CycleCalendarSheetBody> {
  late DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  void _onDayTap(DateTime day) {
    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = day;
        _rangeEnd = null;
      } else if (day.isBefore(_rangeStart!)) {
        _rangeEnd = _rangeStart;
        _rangeStart = day;
      } else {
        _rangeEnd = day;
      }
    });
  }

  int get _selectedLengthDays {
    if (_rangeStart == null) return 0;
    final end = _rangeEnd ?? _rangeStart!;
    return end.difference(_rangeStart!).inDays + 1;
  }

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  bool _isSelected(DateTime day) {
    if (_rangeStart == null) return false;
    final end = _rangeEnd ?? _rangeStart!;
    return !day.isBefore(_rangeStart!) && !day.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = AppStrings.of(context);
    final weekdayHeaders = strings.weekdayHeadersMonToSun;
    final monthNames = strings.monthNames;

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // DateTime.weekday: 1=Monday..7=Sunday, matching _weekdayHeaders order.
    final leadingBlanks = firstOfMonth.weekday - 1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.annulla),
                ),
                Text(strings.selezionaGiorni, style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: _rangeStart == null
                      ? null
                      : () => Navigator.of(context).pop((_rangeStart!, _selectedLengthDays)),
                  child: Text(strings.fatto),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  style: theme.textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            Row(
              children: weekdayHeaders
                  .map((w) => Expanded(
                        child: Center(
                          child: Text(w, style: theme.textTheme.labelSmall),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final day = DateTime(_visibleMonth.year, _visibleMonth.month, index - leadingBlanks + 1);
                final selected = _isSelected(day);
                final isFuture = day.isAfter(DateTime.now());
                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: isFuture ? null : () => _onDayTap(day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? scheme.primary : null,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? scheme.onPrimary
                              : isFuture
                                  ? scheme.outline.withValues(alpha: 0.4)
                                  : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              _rangeStart == null
                  ? strings.toccaIlPrimoGiornoDiMestruazione
                  : strings.mestruazioneDiNGiorni(_selectedLengthDays),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
