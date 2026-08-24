import 'package:supabase_flutter/supabase_flutter.dart';

class TimeBudgetService {
  final _client = Supabase.instance.client;

  Future<bool> hasPromptedToday(String dayPart) async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('time_budgets')
        .select('id')
        .eq('user_id', userId)
        .eq('day_part', dayPart)
        .eq('taken_on', _today())
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<void> savePrompt(String dayPart, int? minutes) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('time_budgets').upsert(
      {'user_id': userId, 'day_part': dayPart, 'taken_on': _today(), 'minutes': minutes},
      onConflict: 'user_id,day_part,taken_on',
    );
  }

  /// The most recent non-skipped answer given today — whichever of the two
  /// prompts (morning/evening) fired last and wasn't skipped.
  Future<int?> loadActiveBudgetMinutes() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('time_budgets')
        .select('minutes, created_at')
        .eq('user_id', userId)
        .eq('taken_on', _today())
        .not('minutes', 'is', null)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['minutes'] as int?;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
