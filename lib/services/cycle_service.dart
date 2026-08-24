import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cycle_info.dart';

class CycleService {
  final _client = Supabase.instance.client;

  Future<CycleInfo?> loadCycleInfo() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('menstrual_cycle_logs')
        .select('period_start_date')
        .eq('user_id', userId)
        .order('period_start_date', ascending: false)
        .limit(6);

    if (rows.isEmpty) return null;

    final starts = rows
        .map((row) => DateTime.parse(row['period_start_date'] as String))
        .toList();

    return CycleInfo.fromStarts(starts);
  }

  Future<void> logPeriodStart(DateTime date) async {
    final userId = _client.auth.currentUser!.id;
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await _client.from('menstrual_cycle_logs').upsert(
      {'user_id': userId, 'period_start_date': dateString},
      onConflict: 'user_id,period_start_date',
    );
  }

  /// Retroactively logs a past period as a real start date + real length —
  /// distinct from [logPeriodStart], which only ever knows "today, length
  /// unknown yet". A real length here replaces CycleHistoryEntry's
  /// population-average estimate for this specific cycle.
  Future<void> logPeriodRange(DateTime startDate, int periodLengthDays) async {
    final userId = _client.auth.currentUser!.id;
    final dateString =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

    await _client.from('menstrual_cycle_logs').upsert(
      {'user_id': userId, 'period_start_date': dateString, 'period_length_days': periodLengthDays},
      onConflict: 'user_id,period_start_date',
    );
  }

  Future<List<DateTime>> loadPeriodStartsHistory({int limit = 12}) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('menstrual_cycle_logs')
        .select('period_start_date')
        .eq('user_id', userId)
        .order('period_start_date', ascending: false)
        .limit(limit);

    return rows.map((row) => DateTime.parse(row['period_start_date'] as String)).toList();
  }

  Future<List<CyclePeriodLog>> loadPeriodLogsHistory({int limit = 12}) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('menstrual_cycle_logs')
        .select('period_start_date, period_length_days')
        .eq('user_id', userId)
        .order('period_start_date', ascending: false)
        .limit(limit);

    return rows
        .map((row) => CyclePeriodLog(
              startDate: DateTime.parse(row['period_start_date'] as String),
              periodLengthDays: row['period_length_days'] as int?,
            ))
        .toList();
  }

  /// Upserts each start individually — logPeriodStart is already idempotent
  /// (unique user_id+date), so importing the same Salute data twice is safe.
  Future<void> importPeriodStarts(List<DateTime> starts) async {
    for (final start in starts) {
      await logPeriodStart(start);
    }
  }
}
