import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_settings.dart';

class SettingsService {
  final _client = Supabase.instance.client;

  Future<AppSettings> loadSettings() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('profiles')
        .select(
          'theme_mode, language, evening_ritual_time, approach, sex, fasting_enabled, nickname, '
          'birth_date, narrative_summary, onboarding_completed',
        )
        .eq('user_id', userId)
        .limit(1);

    if (rows.isEmpty) return AppSettings.defaults;

    final row = rows.first;
    return AppSettings(
      themeMode: _parseThemeMode(row['theme_mode'] as String?),
      language: row['language'] as String? ?? 'it',
      eveningRitualTime: _parseTime(row['evening_ritual_time'] as String?),
      approach: _parseApproach(row['approach'] as String?),
      sex: _parseSex(row['sex'] as String?),
      fastingEnabled: row['fasting_enabled'] as bool? ?? false,
      nickname: row['nickname'] as String?,
      birthDate: row['birth_date'] == null ? null : DateTime.parse(row['birth_date'] as String),
      narrativeSummary: row['narrative_summary'] as String?,
      onboardingCompleted: row['onboarding_completed'] as bool? ?? false,
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

  Future<void> saveApproach(WellnessApproach approach) {
    return _upsert({'approach': approach.name});
  }

  Future<void> saveSex(UserSex sex) {
    return _upsert({'sex': sex.name});
  }

  Future<void> saveFastingEnabled(bool value) {
    return _upsert({'fasting_enabled': value});
  }

  Future<void> saveNickname(String? nickname) {
    return _upsert({'nickname': nickname});
  }

  Future<void> saveBirthDate(DateTime? birthDate) {
    return _upsert({'birth_date': birthDate?.toIso8601String().substring(0, 10)});
  }

  Future<void> saveNarrativeSummary(String? summary) {
    return _upsert({'narrative_summary': summary});
  }

  Future<void> saveOnboardingCompleted() {
    return _upsert({'onboarding_completed': true});
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

  WellnessApproach _parseApproach(String? value) {
    switch (value) {
      case 'natural':
        return WellnessApproach.natural;
      case 'scientific':
        return WellnessApproach.scientific;
      default:
        return WellnessApproach.balanced;
    }
  }

  UserSex _parseSex(String? value) {
    switch (value) {
      case 'female':
        return UserSex.female;
      case 'male':
        return UserSex.male;
      default:
        return UserSex.unspecified;
    }
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
