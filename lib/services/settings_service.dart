import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_settings.dart';

class SettingsService {
  final _client = Supabase.instance.client;

  Future<AppSettings> loadSettings() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('profiles')
        .select('theme_mode, language, evening_ritual_time')
        .eq('user_id', userId)
        .limit(1);

    if (rows.isEmpty) return AppSettings.defaults;

    final row = rows.first;
    return AppSettings(
      themeMode: _parseThemeMode(row['theme_mode'] as String?),
      language: row['language'] as String? ?? 'it',
      eveningRitualTime: _parseTime(row['evening_ritual_time'] as String?),
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) {
    return _upsert({'theme_mode': mode.name});
  }

  Future<void> saveLanguage(String language) {
    return _upsert({'language': language});
  }

  Future<void> saveEveningRitualTime(TimeOfDay time) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return _upsert({'evening_ritual_time': formatted});
  }

  Future<void> _upsert(Map<String, dynamic> values) async {
    final userId = _client.auth.currentUser!.id;

    await _client.from('profiles').upsert({
      'user_id': userId,
      ...values,
    }, onConflict: 'user_id');
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
