import 'package:flutter/material.dart';

enum WellnessApproach { natural, balanced, scientific }

enum UserSex { unspecified, female, male }

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.eveningRitualTime,
    required this.approach,
    required this.sex,
    required this.fastingEnabled,
    required this.nickname,
  });

  final ThemeMode themeMode;
  final String language;
  final TimeOfDay? eveningRitualTime;
  final WellnessApproach approach;
  final UserSex sex;
  final bool fastingEnabled;
  final String? nickname;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    language: 'it',
    eveningRitualTime: null,
    approach: WellnessApproach.balanced,
    sex: UserSex.unspecified,
    fastingEnabled: false,
    nickname: null,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    TimeOfDay? eveningRitualTime,
    WellnessApproach? approach,
    UserSex? sex,
    bool? fastingEnabled,
    String? nickname,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      eveningRitualTime: eveningRitualTime ?? this.eveningRitualTime,
      approach: approach ?? this.approach,
      sex: sex ?? this.sex,
      fastingEnabled: fastingEnabled ?? this.fastingEnabled,
      nickname: nickname ?? this.nickname,
    );
  }
}
