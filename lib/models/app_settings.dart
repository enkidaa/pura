import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.eveningRitualTime,
  });

  final ThemeMode themeMode;
  final String language;
  final TimeOfDay? eveningRitualTime;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    language: 'it',
    eveningRitualTime: null,
  );
}
