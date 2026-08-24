import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around flutter_local_notifications for weekly recurring
/// reminders. Scheduling is local-only — no reminder content ever leaves
/// the device.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.local);
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  /// Deterministic per-(ownerId, weekday) id so re-scheduling the same
  /// reminder cancels/replaces the previous one instead of stacking up.
  static int _notificationId(String ownerId, int weekday) {
    return (ownerId.hashCode.abs() % 100000) * 10 + weekday;
  }

  static Future<void> scheduleWeekly({
    required String ownerId,
    required String title,
    required String body,
    required Set<int> weekdays,
    required TimeOfDay time,
  }) async {
    await cancelAll(ownerId);
    for (final weekday in weekdays) {
      final scheduled = _nextInstanceOfWeekday(weekday, time);
      await _plugin.zonedSchedule(
        id: _notificationId(ownerId, weekday),
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'supplement_reminders',
            'Promemoria integratori',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> cancelAll(String ownerId) async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notificationId(ownerId, weekday));
    }
  }

  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, TimeOfDay time) {
    var scheduled = tz.TZDateTime.now(tz.local);
    scheduled = tz.TZDateTime(
      tz.local,
      scheduled.year,
      scheduled.month,
      scheduled.day,
      time.hour,
      time.minute,
    );
    while (scheduled.weekday != weekday || scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
