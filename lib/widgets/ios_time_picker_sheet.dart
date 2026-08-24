import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A time picker matching iOS's native spinner (the same wheel-style
/// picker Orologio uses to set an alarm), as a Cupertino bottom sheet —
/// replaces Material's `showTimePicker`, which renders as an analog clock
/// dial on iOS instead of the spinner users actually expect there.
///
/// [use24hFormat] defaults to true to match the app's existing convention
/// (Italian locale, no override was ever set on the old `showTimePicker`
/// calls, so it always rendered 24h on an Italian device).
Future<TimeOfDay?> showIosTimePickerSheet({
  required BuildContext context,
  required String title,
  required TimeOfDay initialTime,
  bool use24hFormat = true,
}) {
  var selected = initialTime;
  final now = DateTime.now();
  final initialDateTime = DateTime(now.year, now.month, now.day, initialTime.hour, initialTime.minute);

  return showCupertinoModalPopup<TimeOfDay?>(
    context: context,
    builder: (sheetContext) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: CupertinoTheme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Annulla'),
                  ),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    onPressed: () => Navigator.of(sheetContext).pop(selected),
                    child: const Text('Fatto'),
                  ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: use24hFormat,
                  onDateTimeChanged: (dt) => selected = TimeOfDay.fromDateTime(dt),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
