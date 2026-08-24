import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_spec.dart';

class SupplementSource {
  const SupplementSource({required this.id, required this.text});
  final String id;
  final String text;
}

class SupplementService {
  final _client = Supabase.instance.client;

  Future<ScheduleSpec> loadSchedule(String supplementId) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('supplement_routine')
        .select('schedule_type, times_per_week, weekdays, cycle_on_days, cycle_off_days, cycle_anchor')
        .eq('user_id', userId)
        .eq('supplement_id', supplementId)
        .limit(1);

    if (rows.isEmpty) return const ScheduleSpec();
    return scheduleFromRow(rows.first);
  }

  Future<void> saveSchedule(String supplementId, ScheduleSpec spec) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('supplement_routine')
        .update(scheduleToRow(spec))
        .eq('user_id', userId)
        .eq('supplement_id', supplementId);
  }

  Future<Map<String, ScheduleSpec>> loadSchedulesFor(Set<String> supplementIds) async {
    if (supplementIds.isEmpty) return {};
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('supplement_routine')
        .select(
          'supplement_id, schedule_type, times_per_week, weekdays, cycle_on_days, cycle_off_days, cycle_anchor',
        )
        .eq('user_id', userId)
        .inFilter('supplement_id', supplementIds.toList());

    return {for (final row in rows) row['supplement_id'] as String: scheduleFromRow(row)};
  }

  Future<Set<String>> loadRoutineIds() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('supplement_routine')
        .select('supplement_id')
        .eq('user_id', userId);

    return rows.map((row) => row['supplement_id'] as String).toSet();
  }

  Future<void> addToRoutine(String supplementId) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('supplement_routine').upsert(
      {'user_id': userId, 'supplement_id': supplementId},
      onConflict: 'user_id,supplement_id',
    );
  }

  Future<void> removeFromRoutine(String supplementId) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('supplement_routine')
        .delete()
        .eq('user_id', userId)
        .eq('supplement_id', supplementId);
  }

  Future<Set<String>> loadTodayIntake() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('supplement_intake_logs')
        .select('supplement_id')
        .eq('user_id', userId)
        .eq('taken_on', _todayString());

    return rows.map((row) => row['supplement_id'] as String).toSet();
  }

  Future<void> setIntakeToday(String supplementId, bool taken) async {
    final userId = _client.auth.currentUser!.id;
    final today = _todayString();

    if (taken) {
      await _client.from('supplement_intake_logs').upsert(
        {'user_id': userId, 'supplement_id': supplementId, 'taken_on': today},
        onConflict: 'user_id,supplement_id,taken_on',
      );
    } else {
      await _client
          .from('supplement_intake_logs')
          .delete()
          .eq('user_id', userId)
          .eq('supplement_id', supplementId)
          .eq('taken_on', today);
    }
  }

  Future<String> loadNote(String supplementId) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('supplement_notes')
        .select('note')
        .eq('user_id', userId)
        .eq('supplement_id', supplementId)
        .limit(1);

    if (rows.isEmpty) return '';
    return rows.first['note'] as String? ?? '';
  }

  Future<void> saveNote(String supplementId, String note) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('supplement_notes').upsert(
      {'user_id': userId, 'supplement_id': supplementId, 'note': note},
      onConflict: 'user_id,supplement_id',
    );
  }

  Future<List<SupplementSource>> loadSources(String supplementId) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('supplement_sources')
        .select('id, source')
        .eq('user_id', userId)
        .eq('supplement_id', supplementId)
        .order('created_at');

    return rows
        .map((row) => SupplementSource(id: row['id'] as String, text: row['source'] as String))
        .toList();
  }

  Future<void> addSource(String supplementId, String source) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('supplement_sources').insert({
      'user_id': userId,
      'supplement_id': supplementId,
      'source': source,
    });
  }

  Future<void> removeSource(String sourceId) async {
    await _client.from('supplement_sources').delete().eq('id', sourceId);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
