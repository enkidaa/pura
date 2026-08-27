import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

/// Shown once, right after signup (see home_shell.dart) — the same
/// preferences already editable one-by-one in Profilo, just gathered into
/// a single first-run form so a new user doesn't have to discover them by
/// wandering into Profilo on their own. Answers are saved as each control
/// changes (same as Profilo), so closing this mid-way loses nothing.
class OnboardingQuizScreen extends StatefulWidget {
  const OnboardingQuizScreen({super.key});

  @override
  State<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends State<OnboardingQuizScreen> {
  final _settingsService = SettingsService();
  final _nicknameController = TextEditingController();

  AppSettings _settings = AppSettings.defaults;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await _settingsService.loadSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _nicknameController.text = settings.nickname ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveNickname() async {
    final trimmed = _nicknameController.text.trim();
    try {
      await _settingsService.saveNickname(trimmed.isEmpty ? null : trimmed);
    } catch (_) {
      // Non-blocking — the field just keeps the unsaved text locally.
    }
  }

  Future<void> _setApproach(WellnessApproach approach) async {
    setState(() => _settings = _settings.copyWith(approach: approach));
    try {
      await _settingsService.saveApproach(approach);
    } catch (_) {
      // Non-critical here — Profilo lets them retry later.
    }
  }

  Future<void> _setSex(UserSex sex) async {
    setState(() => _settings = _settings.copyWith(sex: sex));
    try {
      await _settingsService.saveSex(sex);
    } catch (_) {
      // Non-critical.
    }
  }

  Future<void> _setFastingEnabled(bool value) async {
    setState(() => _settings = _settings.copyWith(fastingEnabled: value));
    try {
      await _settingsService.saveFastingEnabled(value);
    } catch (_) {
      // Non-critical.
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _settings = _settings.copyWith(themeMode: mode));
    themeModeNotifier.value = mode;
    try {
      await _settingsService.saveThemeMode(mode);
    } catch (_) {
      // Non-critical.
    }
  }

  Future<void> _setLanguage(String language) async {
    setState(() => _settings = _settings.copyWith(language: language));
    appLocaleNotifier.value = localeFromCode(language);
    try {
      await _settingsService.saveLanguage(language);
    } catch (_) {
      // Non-critical.
    }
  }

  Future<void> _finish() async {
    await _saveNickname();
    try {
      await _settingsService.saveOnboardingCompleted();
    } catch (_) {
      // If this fails the quiz just shows again next launch — harmless.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  PageHeader(
                    eyebrow: strings.tuoSoloSeVuoi,
                    title: strings.benvenutoInPura,
                    subtitle: strings.onboardingSottotitolo,
                  ),
                  const SizedBox(height: 24),
                  Text(strings.nickname, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicknameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveNickname(),
                    onTapOutside: (_) => _saveNickname(),
                    decoration: InputDecoration(hintText: strings.esEnkida),
                  ),
                  const SizedBox(height: 24),
                  Text(strings.approccioAlBenessere, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<WellnessApproach>(
                    segments: [
                      ButtonSegment(value: WellnessApproach.natural, label: Text(strings.naturale)),
                      ButtonSegment(value: WellnessApproach.balanced, label: Text(strings.bilanciato)),
                      ButtonSegment(value: WellnessApproach.scientific, label: Text(strings.scientifico)),
                    ],
                    selected: {_settings.approach},
                    onSelectionChanged: (selection) => _setApproach(selection.first),
                  ),
                  const SizedBox(height: 24),
                  Text(strings.sesso, style: theme.textTheme.labelMedium),
                  Text(strings.sessoSpiegazione, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  SegmentedButton<UserSex>(
                    segments: [
                      ButtonSegment(value: UserSex.unspecified, label: Text(strings.nonSpecificato)),
                      ButtonSegment(value: UserSex.female, label: Text(strings.donna)),
                      ButtonSegment(value: UserSex.male, label: Text(strings.uomo)),
                    ],
                    selected: {_settings.sex},
                    onSelectionChanged: (selection) => _setSex(selection.first),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    blur: 0,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.tracciaDigiuno),
                      subtitle: Text(strings.digiunoSettingSpiegazione),
                      value: _settings.fastingEnabled,
                      onChanged: _setFastingEnabled,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(strings.aspetto, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(value: ThemeMode.light, label: Text(strings.chiaro)),
                      ButtonSegment(value: ThemeMode.dark, label: Text(strings.scuro)),
                      ButtonSegment(value: ThemeMode.system, label: Text(strings.auto)),
                    ],
                    selected: {_settings.themeMode},
                    onSelectionChanged: (selection) => _setThemeMode(selection.first),
                  ),
                  const SizedBox(height: 24),
                  Text(strings.linguaLabel, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'it', label: Text('Italiano')),
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'fr', label: Text('Français')),
                    ],
                    selected: {_settings.language},
                    onSelectionChanged: (selection) => _setLanguage(selection.first),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _finish,
                    child: Text(strings.iniziaOra),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(strings.saltaOnboarding),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
