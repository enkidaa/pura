import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/supplement.dart';

class SupplementService {
  final _client = Supabase.instance.client;

  Future<List<Supplement>> loadSupplements() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('user_supplements')
        .select('id, name, category')
        .eq('user_id', userId)
        .order('created_at');

    return rows
        .map((row) => Supplement(
              id: row['id'] as String,
              name: row['name'] as String,
              category: row['category'] == 'scientific'
                  ? SupplementCategory.scientific
                  : SupplementCategory.natural,
            ))
        .toList();
  }

  Future<void> addSupplement(String name, SupplementCategory category) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('user_supplements').insert({
      'user_id': userId,
      'name': name,
      'category': category.name,
    });
  }

  Future<void> removeSupplement(String id) async {
    await _client.from('user_supplements').delete().eq('id', id);
  }

  Future<Set<String>> loadTodayIntake() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('supplement_intake_logs')
        .select('supplement_id')
        .eq('user_id', userId)
        .eq('taken_on', _todayString());

    return rows.map((row) => row['supplement_id'] as String).toSet();
  }

  Future<void> setIntakeToday(String supplementId, bool taken) async {
    final userId = _client.auth.currentUser!.id;
    final today = _todayString();

    if (taken) {
      await _client.from('supplement_intake_logs').upsert(
        {'user_id': userId, 'supplement_id': supplementId, 'taken_on': today},
        onConflict: 'user_id,supplement_id,taken_on',
      );
    } else {
      await _client
          .from('supplement_intake_logs')
          .delete()
          .eq('user_id', userId)
          .eq('supplement_id', supplementId)
          .eq('taken_on', today);
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
