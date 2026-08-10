import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sleep_log.dart';

class SleepService {
  final _client = Supabase.instance.client;

  Future<SleepLog?> loadLastNight() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('sleep_logs')
        .select('bedtime, wake_time')
        .eq('user_id', userId)
        .eq('sleep_date', _todayString())
        .limit(1);

    if (rows.isEmpty) return null;

    return SleepLog(
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
        .select('bedtime, wake_time')
        .eq('user_id', userId)
        .order('sleep_date', ascending: false)
        .limit(7);

    return rows
        .map((row) => SleepLog(
              bedtime: DateTime.parse(row['bedtime'] as String),
              wakeTime: DateTime.parse(row['wake_time'] as String),
            ))
        .toList();
  }

  Future<void> saveLastNight({
    required DateTime bedtime,
    required DateTime wakeTime,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('sleep_logs').upsert(
      {
        'user_id': userId,
        'sleep_date': _todayString(),
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
