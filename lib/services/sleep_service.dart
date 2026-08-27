import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sleep_log.dart';

class SleepService {
  final _client = Supabase.instance.client;

  Future<SleepLog?> loadLastNight() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('sleep_logs')
        .select('sleep_date, bedtime, wake_time')
        .eq('user_id', userId)
        .eq('sleep_date', _todayString())
        .limit(1);

    if (rows.isEmpty) return null;

    return SleepLog(
      sleepDate: rows.first['sleep_date'] as String,
      bedtime: DateTime.parse(rows.first['bedtime'] as String),
      wakeTime: DateTime.parse(rows.first['wake_time'] as String),
    );
  }

  // Last 7 nights, most recent first — used to gauge circadian regularity
  // (how consistent bedtime/wake time are), not a new tracked domain of its
  // own, just a different read of the same sleep_logs data.
  Future<List<SleepLog>> loadRecentSleepLogs() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('sleep_logs')
        .select('sleep_date, bedtime, wake_time')
        .eq('user_id', userId)
        .order('sleep_date', ascending: false)
        .limit(7);

    return rows
        .map((row) => SleepLog(
              sleepDate: row['sleep_date'] as String,
              bedtime: DateTime.parse(row['bedtime'] as String),
              wakeTime: DateTime.parse(row['wake_time'] as String),
            ))
        .toList();
  }

  Future<void> saveLastNight({
    required DateTime bedtime,
    required DateTime wakeTime,
  }) {
    return saveNight(sleepDate: _todayString(), bedtime: bedtime, wakeTime: wakeTime);
  }

  /// Corrects a specific night by its own sleep_date, rather than always
  /// writing to today's row — used to fix a past night that was logged
  /// badly, without creating a duplicate entry for that date.
  Future<void> saveNight({
    required String sleepDate,
    required DateTime bedtime,
    required DateTime wakeTime,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('sleep_logs').upsert(
      {
        'user_id': userId,
        'sleep_date': sleepDate,
        'bedtime': bedtime.toIso8601String(),
        'wake_time': wakeTime.toIso8601String(),
      },
      onConflict: 'user_id,sleep_date',
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
