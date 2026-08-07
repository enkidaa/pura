import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_theme.dart';
import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _settingsService = SettingsService();

  AppSettings _settings = AppSettings.defaults;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.loadSettings();
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _settings = AppSettings(
          themeMode: mode,
          language: _settings.language,
          eveningRitualTime: _settings.eveningRitualTime,
        ));
    themeModeNotifier.value = mode;

    try {
      await _settingsService.saveThemeMode(mode);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile salvare, riprova')));
    }
  }

  Future<void> _setLanguage(String language) async {
    setState(() => _settings = AppSettings(
          themeMode: _settings.themeMode,
          language: language,
          eveningRitualTime: _settings.eveningRitualTime,
        ));

    try {
      await _settingsService.saveLanguage(language);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile salvare, riprova')));
    }
  }

  Future<void> _pickEveningRitualTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settings.eveningRitualTime ?? const TimeOfDay(hour: 20, minute: 30),
      helpText: 'Suggerisci il rituale serale dopo le',
    );
    if (picked == null) return;

    setState(() => _settings = AppSettings(
          themeMode: _settings.themeMode,
          language: _settings.language,
          eveningRitualTime: picked,
        ));

    try {
      await _settingsService.saveEveningRitualTime(picked);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile salvare, riprova')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(email, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Text('Aspetto', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Chiaro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Scuro')),
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
            ],
            selected: {_settings.themeMode},
            onSelectionChanged: (selection) => _setThemeMode(selection.first),
          ),
          const SizedBox(height: 24),
          Text('Lingua', style: Theme.of(context).textTheme.titleMedium),
          const Text(
            'Solo salvata per ora — l\'app resta in italiano, non c\'è ancora traduzione.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'it', label: Text('Italiano')),
              ButtonSegment(value: 'en', label: Text('Inglese')),
            ],
            selected: {_settings.language},
            onSelectionChanged: (selection) => _setLanguage(selection.first),
          ),
          const SizedBox(height: 24),
          Text('Rituale serale', style: Theme.of(context).textTheme.titleMedium),
          const Text(
            'Salvato per ora — non ancora usato (routine serale non esiste ancora).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickEveningRitualTime,
            child: Text(
              _settings.eveningRitualTime == null
                  ? 'Imposta orario'
                  : 'Suggerisci dopo le ${_settings.eveningRitualTime!.format(context)}',
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => AuthService().signOut(),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
  }
}
