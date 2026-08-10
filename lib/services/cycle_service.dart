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
}
