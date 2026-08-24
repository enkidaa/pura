import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineStepSource {
  const RoutineStepSource({required this.id, required this.text});
  final String id;
  final String text;
}

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

  Future<String> loadNote(String stepId) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('routine_step_notes')
        .select('note')
        .eq('user_id', userId)
        .eq('step_id', stepId)
        .limit(1);

    if (rows.isEmpty) return '';
    return rows.first['note'] as String? ?? '';
  }

  Future<void> saveNote(String stepId, String note) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('routine_step_notes').upsert(
      {'user_id': userId, 'step_id': stepId, 'note': note},
      onConflict: 'user_id,step_id',
    );
  }

  Future<List<RoutineStepSource>> loadSources(String stepId) async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('routine_step_sources')
        .select('id, source')
        .eq('user_id', userId)
        .eq('step_id', stepId)
        .order('created_at');

    return rows
        .map((row) => RoutineStepSource(id: row['id'] as String, text: row['source'] as String))
        .toList();
  }

  Future<void> addSource(String stepId, String source) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('routine_step_sources').insert({
      'user_id': userId,
      'step_id': stepId,
      'source': source,
    });
  }

  Future<void> removeSource(String sourceId) async {
    await _client.from('routine_step_sources').delete().eq('id', sourceId);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
