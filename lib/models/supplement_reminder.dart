import 'package:flutter/material.dart';

class SupplementReminder {
  const SupplementReminder({
    required this.supplementId,
    required this.weekdays,
    required this.time,
    required this.enabled,
  });

  final String supplementId;

  /// DateTime.weekday values: 1=Monday .. 7=Sunday.
  final Set<int> weekdays;
  final TimeOfDay time;
  final bool enabled;

  SupplementReminder copyWith({
    Set<int>? weekdays,
    TimeOfDay? time,
    bool? enabled,
  }) {
    return SupplementReminder(
      supplementId: supplementId,
      weekdays: weekdays ?? this.weekdays,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
    );
  }
}
