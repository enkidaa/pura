import 'package:supabase_flutter/supabase_flutter.dart';

class MixDiaryEntry {
  const MixDiaryEntry({required this.mixName, required this.madeAt});

  final String mixName;
  final DateTime madeAt;
}

class LabService {
  final _client = Supabase.instance.client;

  Future<Set<String>> loadIngredients() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('user_ingredients')
        .select('ingredient')
        .eq('user_id', userId);

    return rows.map((row) => row['ingredient'] as String).toSet();
  }

  Future<void> addIngredient(String ingredient) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('user_ingredients').upsert(
      {'user_id': userId, 'ingredient': ingredient},
      onConflict: 'user_id,ingredient',
    );
  }

  Future<void> removeIngredient(String ingredient) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('user_ingredients')
        .delete()
        .eq('user_id', userId)
        .eq('ingredient', ingredient);
  }

  Future<void> logMixMade(String mixName) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('mix_diary_logs').insert({
      'user_id': userId,
      'mix_name': mixName,
    });
  }

  Future<List<MixDiaryEntry>> loadRecentDiary() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('mix_diary_logs')
        .select('mix_name, made_at')
        .eq('user_id', userId)
        .order('made_at', ascending: false)
        .limit(10);

    return rows
        .map((row) => MixDiaryEntry(
              mixName: row['mix_name'] as String,
              madeAt: DateTime.parse(row['made_at'] as String),
            ))
        .toList();
  }
}
