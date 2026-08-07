import 'package:supabase_flutter/supabase_flutter.dart';

class PlantDiversityService {
  final _client = Supabase.instance.client;

  Future<Set<String>> loadUniquePlantsThisWeek() async {
    final userId = _client.auth.currentUser!.id;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));

    final rows = await _client
        .from('plant_diversity_logs')
        .select('plant_name')
        .eq('user_id', userId)
        .gte('logged_on', _dateString(sevenDaysAgo));

    return rows.map((row) => row['plant_name'] as String).toSet();
  }

  Future<void> logPlant(String plantName) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('plant_diversity_logs').insert({
      'user_id': userId,
      'plant_name': plantName,
    });
  }

  String _dateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
