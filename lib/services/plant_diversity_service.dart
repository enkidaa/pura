import 'package:supabase_flutter/supabase_flutter.dart';

class PlantLog {
  const PlantLog({required this.name, required this.loggedOn});
  final String name;
  final DateTime loggedOn;
}

class PlantDiversityService {
  final _client = Supabase.instance.client;

  DateTime _mondayOfThisWeek() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }

  Future<Set<String>> loadUniquePlantsThisWeek() async {
    final logs = await loadLogsThisWeek();
    return logs.map((l) => l.name).toSet();
  }

  Future<List<PlantLog>> loadLogsThisWeek() async {
    final userId = _client.auth.currentUser!.id;
    final monday = _mondayOfThisWeek();

    final rows = await _client
        .from('plant_diversity_logs')
        .select('plant_name, logged_on')
        .eq('user_id', userId)
        .gte('logged_on', _dateString(monday))
        .order('logged_on');

    return rows
        .map((row) => PlantLog(
              name: row['plant_name'] as String,
              loggedOn: DateTime.parse(row['logged_on'] as String),
            ))
        .toList();
  }

  Future<void> logPlant(String plantName) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('plant_diversity_logs').insert({
      'user_id': userId,
      'plant_name': plantName,
    });
  }

  /// Removes every log of this plant from the current week — a second tap
  /// on an already-selected chip un-selects it, correcting mistaps.
  Future<void> removePlantThisWeek(String plantName) async {
    final userId = _client.auth.currentUser!.id;
    final monday = _mondayOfThisWeek();

    await _client
        .from('plant_diversity_logs')
        .delete()
        .eq('user_id', userId)
        .ilike('plant_name', plantName)
        .gte('logged_on', _dateString(monday));
  }

  String _dateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
