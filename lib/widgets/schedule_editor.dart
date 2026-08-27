import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/schedule_spec.dart';

/// Editor per la programmazione dell'assunzione — separata dalla presenza
/// in routine (già gestita altrove) e dai promemoria (notifiche locali).
class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({super.key, required this.spec, required this.onChanged});

  final ScheduleSpec spec;
  final ValueChanged<ScheduleSpec> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.programmazione, style: theme.textTheme.labelMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ScheduleType.values.map((type) {
            return ChoiceChip(
              label: Text(scheduleTypeLabel(type, strings)),
              selected: spec.type == type,
              onSelected: (_) => onChanged(_defaultsFor(type)),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (spec.type == ScheduleType.timesPerWeek) _buildTimesPerWeek(context),
        if (spec.type == ScheduleType.specificWeekdays) _buildSpecificWeekdays(context),
        if (spec.type == ScheduleType.cyclic) _buildCyclic(context),
      ],
    );
  }

  ScheduleSpec _defaultsFor(ScheduleType type) {
    switch (type) {
      case ScheduleType.daily:
        return const ScheduleSpec();
      case ScheduleType.timesPerWeek:
        return ScheduleSpec(type: type, timesPerWeek: spec.timesPerWeek ?? 3);
      case ScheduleType.specificWeekdays:
        return ScheduleSpec(type: type, weekdays: spec.weekdays.isEmpty ? {1, 3, 5} : spec.weekdays);
      case ScheduleType.cyclic:
        return ScheduleSpec(
          type: type,
          cycleOnDays: spec.cycleOnDays ?? 7,
          cycleOffDays: spec.cycleOffDays ?? 14,
          cycleAnchor: spec.cycleAnchor ?? DateTime.now(),
        );
    }
  }

  Map<int, String> _weekdayLabels(BuildContext context) {
    final letters = AppStrings.of(context).weekdayLettersMonToSun;
    return {for (var i = 0; i < 7; i++) i + 1: letters[i]};
  }

  Widget _buildTimesPerWeek(BuildContext context) {
    final strings = AppStrings.of(context);
    final weekdayLabels = _weekdayLabels(context);
    final n = spec.timesPerWeek ?? 3;
    final days = autoDistributeWeekdays(n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: n > 1 ? () => onChanged(spec.copyWith(timesPerWeek: n - 1)) : null,
            ),
            Text(strings.nVolteASettimana(n), style: Theme.of(context).textTheme.bodyLarge),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: n < 7 ? () => onChanged(spec.copyWith(timesPerWeek: n + 1)) : null,
            ),
          ],
        ),
        Text(
          strings.giorniAutoDistribuiti(days.map((d) => weekdayLabels[d]).join(', ')),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSpecificWeekdays(BuildContext context) {
    final weekdayLabels = _weekdayLabels(context);
    return Wrap(
      spacing: 6,
      children: weekdayLabels.entries.map((entry) {
        final selected = spec.weekdays.contains(entry.key);
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) {
            final weekdays = Set<int>.from(spec.weekdays);
            if (selected) {
              weekdays.remove(entry.key);
            } else {
              weekdays.add(entry.key);
            }
            onChanged(spec.copyWith(weekdays: weekdays));
          },
        );
      }).toList(),
    );
  }

  Widget _buildCyclic(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _CycleStepper(
                label: strings.giorniAttivi,
                value: spec.cycleOnDays ?? 7,
                onChanged: (v) => onChanged(spec.copyWith(cycleOnDays: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CycleStepper(
                label: strings.giorniPausa,
                value: spec.cycleOffDays ?? 14,
                onChanged: (v) => onChanged(spec.copyWith(cycleOffDays: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          strings.daOggiCiclico(spec.cycleOnDays ?? 7, spec.cycleOffDays ?? 14),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CycleStepper extends StatelessWidget {
  const _CycleStepper({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
            Text('$value'),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}
