import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fasting_log.dart';

class FastingService {
  final _client = Supabase.instance.client;

  /// The single current fasting/eating state — not scoped to "today", since
  /// a fast routinely spans midnight (see migration 0030 for why keying by
  /// day was actually broken).
  Future<FastingLog> loadCurrent() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('fasting_logs')
        .select('first_meal_time, last_meal_time')
        .eq('user_id', userId)
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

  /// [closingFastStart] is the *previous* lastMealTime — pass it when this
  /// call ends a fast (i.e. the state was fasting, not eating), so the
  /// completed fast gets a real history row instead of just moving the
  /// current-state pointer forward.
  Future<void> markFirstMeal(DateTime time, {DateTime? closingFastStart}) async {
    await _mark('first_meal_time', time);
    if (closingFastStart != null) {
      await _logWindow(kind: 'fast', startedAt: closingFastStart, endedAt: time);
    }
  }

  /// [closingEatingStart] is the *previous* firstMealTime — pass it when
  /// this call ends an eating window, for the same reason as above.
  Future<void> markLastMeal(DateTime time, {DateTime? closingEatingStart}) async {
    await _mark('last_meal_time', time);
    if (closingEatingStart != null) {
      await _logWindow(kind: 'eating', startedAt: closingEatingStart, endedAt: time);
    }
  }

  Future<void> _mark(String column, DateTime time) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('fasting_logs').upsert(
      {'user_id': userId, column: time.toIso8601String()},
      onConflict: 'user_id',
    );
  }

  Future<void> _logWindow({
    required String kind,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('fasting_windows').insert({
      'user_id': userId,
      'kind': kind,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
    });
  }
}
