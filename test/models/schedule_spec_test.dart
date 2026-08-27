import 'package:flutter_test/flutter_test.dart';
import 'package:pura/models/schedule_spec.dart';

void main() {
  group('autoDistributeWeekdays', () {
    test('spreads evenly across the week', () {
      expect(autoDistributeWeekdays(1), {1});
      expect(autoDistributeWeekdays(3), {1, 3, 5});
      expect(autoDistributeWeekdays(7), {1, 2, 3, 4, 5, 6, 7});
    });

    test('handles the edges without throwing', () {
      expect(autoDistributeWeekdays(0), isEmpty);
      expect(autoDistributeWeekdays(-1), isEmpty);
      expect(autoDistributeWeekdays(10), {1, 2, 3, 4, 5, 6, 7});
    });
  });

  group('ScheduleSpec.isDueOn', () {
    test('daily is always due', () {
      const spec = ScheduleSpec();
      expect(spec.isDueOn(DateTime(2026, 1, 1)), isTrue);
      expect(spec.isDueOn(DateTime(2026, 6, 15)), isTrue);
    });

    test('specificWeekdays only matches the listed weekdays', () {
      const spec = ScheduleSpec(type: ScheduleType.specificWeekdays, weekdays: {1, 3, 5});
      // 2026-08-24 is a Monday (weekday 1).
      expect(spec.isDueOn(DateTime(2026, 8, 24)), isTrue);
      expect(spec.isDueOn(DateTime(2026, 8, 25)), isFalse); // Tuesday
      expect(spec.isDueOn(DateTime(2026, 8, 26)), isTrue); // Wednesday
    });

    test('timesPerWeek defers to autoDistributeWeekdays', () {
      const spec = ScheduleSpec(type: ScheduleType.timesPerWeek, timesPerWeek: 3);
      final due = autoDistributeWeekdays(3);
      for (var weekday = 1; weekday <= 7; weekday++) {
        // 2026-08-24 is a Monday, so date.weekday == weekday for this week.
        final date = DateTime(2026, 8, 24).add(Duration(days: weekday - 1));
        expect(spec.isDueOn(date), due.contains(weekday), reason: 'weekday $weekday');
      }
    });

    test('cyclic is on for cycleOnDays then off for cycleOffDays, repeating', () {
      final spec = ScheduleSpec(
        type: ScheduleType.cyclic,
        cycleOnDays: 3,
        cycleOffDays: 2,
        cycleAnchor: DateTime(2026, 1, 1),
      );
      // Period is 5 days: on,on,on,off,off, then repeats.
      expect(spec.isDueOn(DateTime(2026, 1, 1)), isTrue); // day 0: on
      expect(spec.isDueOn(DateTime(2026, 1, 2)), isTrue); // day 1: on
      expect(spec.isDueOn(DateTime(2026, 1, 3)), isTrue); // day 2: on
      expect(spec.isDueOn(DateTime(2026, 1, 4)), isFalse); // day 3: off
      expect(spec.isDueOn(DateTime(2026, 1, 5)), isFalse); // day 4: off
      expect(spec.isDueOn(DateTime(2026, 1, 6)), isTrue); // day 5: back on
    });

    test('cyclic before the anchor date still resolves without throwing', () {
      final spec = ScheduleSpec(
        type: ScheduleType.cyclic,
        cycleOnDays: 3,
        cycleOffDays: 2,
        cycleAnchor: DateTime(2026, 1, 10),
      );
      // A date before the anchor exercises the negative-modulo branch.
      expect(() => spec.isDueOn(DateTime(2026, 1, 1)), returnsNormally);
    });
  });
}
