import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/supplement_reminder.dart';
import 'notification_service.dart';

class SupplementReminderService {
  final _client = Supabase.instance.client;

  Future<SupplementReminder> load(String supplementId) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('supplement_reminders')
        .select('weekdays, hour, minute, enabled')
        .eq('user_id', userId)
        .eq('supplement_id', supplementId)
        .limit(1);

    if (rows.isEmpty) {
      return SupplementReminder(
        supplementId: supplementId,
        weekdays: const {},
        time: const TimeOfDay(hour: 9, minute: 0),
        enabled: false,
      );
    }
    final row = rows.first;
    return SupplementReminder(
      supplementId: supplementId,
      weekdays: (row['weekdays'] as List).map((w) => w as int).toSet(),
      time: TimeOfDay(hour: row['hour'] as int, minute: row['minute'] as int),
      enabled: row['enabled'] as bool,
    );
  }

  Future<void> save(SupplementReminder reminder, {required String supplementName}) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('supplement_reminders').upsert({
      'user_id': userId,
      'supplement_id': reminder.supplementId,
      'weekdays': reminder.weekdays.toList(),
      'hour': reminder.time.hour,
      'minute': reminder.time.minute,
      'enabled': reminder.enabled,
    }, onConflict: 'user_id,supplement_id');

    if (reminder.enabled && reminder.weekdays.isNotEmpty) {
      await NotificationService.scheduleWeekly(
        ownerId: reminder.supplementId,
        title: 'Promemoria integratore',
        body: 'È il momento di: $supplementName',
        weekdays: reminder.weekdays,
        time: reminder.time,
      );
    } else {
      await NotificationService.cancelAll(reminder.supplementId);
    }
  }
}
