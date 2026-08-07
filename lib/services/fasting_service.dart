import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fasting_log.dart';

class FastingService {
  final _client = Supabase.instance.client;

  Future<FastingLog> loadToday() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('fasting_logs')
        .select('first_meal_time, last_meal_time')
        .eq('user_id', userId)
        .eq('log_date', _todayString())
        .limit(1);

    if (rows.isEmpty) return const FastingLog();

    final row = rows.first;
    return FastingLog(
      firstMealTime: row['first_meal_time'] == null
          ? null
          : DateTime.parse(row['first_meal_time'] as String),
      lastMealTime: row['last_meal_time'] == null
          ? null
          : DateTime.parse(row['last_meal_time'] as String),
    );
  }

  Future<void> markFirstMealNow() => _markNow('first_meal_time');

  Future<void> markLastMealNow() => _markNow('last_meal_time');

  Future<void> _markNow(String column) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('fasting_logs').upsert(
      {
        'user_id': userId,
        'log_date': _todayString(),
        column: DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,log_date',
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
