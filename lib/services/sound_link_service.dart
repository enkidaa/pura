import 'package:supabase_flutter/supabase_flutter.dart';

class SoundLinkService {
  final _client = Supabase.instance.client;

  Future<String?> loadToday() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('sound_links')
        .select('url')
        .eq('user_id', userId)
        .eq('log_date', _todayString())
        .limit(1);

    if (rows.isEmpty) return null;
    return rows.first['url'] as String;
  }

  Future<void> saveToday(String url) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('sound_links').upsert(
      {'user_id': userId, 'log_date': _todayString(), 'url': url},
      onConflict: 'user_id,log_date',
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
