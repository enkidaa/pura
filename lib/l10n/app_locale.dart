import 'package:flutter/foundation.dart';

enum AppLocale { it, en, fr }

AppLocale localeFromCode(String? code) {
  switch (code) {
    case 'en':
      return AppLocale.en;
    case 'fr':
      return AppLocale.fr;
    default:
      return AppLocale.it;
  }
}

String localeCode(AppLocale locale) {
  switch (locale) {
    case AppLocale.en:
      return 'en';
    case AppLocale.fr:
      return 'fr';
    case AppLocale.it:
      return 'it';
  }
}

/// Current app language. Loaded from settings at startup (see home_shell.dart)
/// and updated live when the user switches it in Profilo.
final appLocaleNotifier = ValueNotifier<AppLocale>(AppLocale.it);
