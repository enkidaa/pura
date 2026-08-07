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
