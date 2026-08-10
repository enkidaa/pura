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
  });

  final ThemeMode themeMode;
  final String language;
  final TimeOfDay? eveningRitualTime;
  final WellnessApproach approach;
  final UserSex sex;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    language: 'it',
    eveningRitualTime: null,
    approach: WellnessApproach.balanced,
    sex: UserSex.unspecified,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    TimeOfDay? eveningRitualTime,
    WellnessApproach? approach,
    UserSex? sex,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      eveningRitualTime: eveningRitualTime ?? this.eveningRitualTime,
      approach: approach ?? this.approach,
      sex: sex ?? this.sex,
    );
  }
}
