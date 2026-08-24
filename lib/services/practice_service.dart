import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_spec.dart';

class PracticeService {
  final _client = Supabase.instance.client;

  Future<ScheduleSpec> loadSchedule(String practiceId) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('practice_routine')
        .select('schedule_type, times_per_week, weekdays, cycle_on_days, cycle_off_days, cycle_anchor')
        .eq('user_id', userId)
        .eq('practice_id', practiceId)
        .limit(1);

    if (rows.isEmpty) return const ScheduleSpec();
    return scheduleFromRow(rows.first);
  }

  Future<void> saveSchedule(String practiceId, ScheduleSpec spec) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('practice_routine')
        .update(scheduleToRow(spec))
        .eq('user_id', userId)
        .eq('practice_id', practiceId);
  }

  Future<Map<String, ScheduleSpec>> loadSchedulesFor(Set<String> practiceIds) async {
    if (practiceIds.isEmpty) return {};
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('practice_routine')
        .select(
          'practice_id, schedule_type, times_per_week, weekdays, cycle_on_days, cycle_off_days, cycle_anchor',
        )
        .eq('user_id', userId)
        .inFilter('practice_id', practiceIds.toList());

    return {for (final row in rows) row['practice_id'] as String: scheduleFromRow(row)};
  }

  Future<Set<String>> loadRoutinePracticeIds() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('practice_routine')
        .select('practice_id')
        .eq('user_id', userId);

    return rows.map((row) => row['practice_id'] as String).toSet();
  }

  Future<void> addToRoutine(String practiceId) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('practice_routine').upsert(
      {'user_id': userId, 'practice_id': practiceId},
      onConflict: 'user_id,practice_id',
    );
  }

  Future<void> removeFromRoutine(String practiceId) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('practice_routine')
        .delete()
        .eq('user_id', userId)
        .eq('practice_id', practiceId);
  }
}
