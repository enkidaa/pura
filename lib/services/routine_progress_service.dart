import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineProgressService {
  final _client = Supabase.instance.client;

  Future<Set<String>> loadCompletedToday() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('routine_completions')
        .select('step_id')
        .eq('user_id', userId)
        .eq('completed_on', _todayString());

    return rows.map((row) => row['step_id'] as String).toSet();
  }

  Future<void> setStepCompleted(String stepId, bool completed) async {
    final userId = _client.auth.currentUser!.id;
    final today = _todayString();

    if (completed) {
      await _client.from('routine_completions').upsert(
        {'user_id': userId, 'step_id': stepId, 'completed_on': today},
        onConflict: 'user_id,step_id,completed_on',
      );
    } else {
      await _client
          .from('routine_completions')
          .delete()
          .eq('user_id', userId)
          .eq('step_id', stepId)
          .eq('completed_on', today);
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
