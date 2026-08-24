import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_theme.dart';
import '../l10n/app_locale.dart';
import '../models/app_settings.dart';
import '../models/user_document.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _settingsService = SettingsService();
  final _documentService = DocumentService();

  AppSettings _settings = AppSettings.defaults;
  bool _loading = true;
  final _nicknameController = TextEditingController();

  List<UserDocument> _documents = [];
  bool _documentsLoading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDocuments();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.loadSettings();
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
    setState(() => _settings = _settings.copyWith(nickname: trimmed.isEmpty ? null : trimmed));
    await _save(() => _settingsService.saveNickname(trimmed.isEmpty ? null : trimmed));
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _settings = _settings.copyWith(themeMode: mode));
    themeModeNotifier.value = mode;
    await _save(() => _settingsService.saveThemeMode(mode));
  }

  Future<void> _setLanguage(String language) async {
    setState(() => _settings = _settings.copyWith(language: language));
    appLocaleNotifier.value = localeFromCode(language);
    await _save(() => _settingsService.saveLanguage(language));
  }

  Future<void> _setApproach(WellnessApproach approach) async {
    setState(() => _settings = _settings.copyWith(approach: approach));
    await _save(() => _settingsService.saveApproach(approach));
  }

  Future<void> _setSex(UserSex sex) async {
    setState(() => _settings = _settings.copyWith(sex: sex));
    await _save(() => _settingsService.saveSex(sex));
  }

  Future<void> _setFastingEnabled(bool value) async {
    setState(() => _settings = _settings.copyWith(fastingEnabled: value));
    await _save(() => _settingsService.saveFastingEnabled(value));
  }

  Future<void> _pickEveningRitualTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settings.eveningRitualTime ?? const TimeOfDay(hour: 20, minute: 30),
      helpText: 'Suggerisci il rituale serale dopo le',
    );
    if (picked == null) return;

    setState(() => _settings = _settings.copyWith(eveningRitualTime: picked));
    await _save(() => _settingsService.saveEveningRitualTime(picked));
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _settings.birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Data di nascita',
    );
    if (picked == null) return;

    setState(() => _settings = _settings.copyWith(birthDate: picked));
    await _save(() => _settingsService.saveBirthDate(picked));
  }

  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile salvare, riprova')));
    }
  }

  Future<void> _loadDocuments() async {
    try {
      final documents = await _documentService.loadDocuments();
      setState(() {
        _documents = documents;
        _documentsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _documentsLoading = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _uploading = true);

    final extension = path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };

    try {
      await _documentService.uploadDocument(
        file: File(path),
        label: path.split('/').last,
        mimeType: mimeType,
      );
      await _loadDocuments();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile caricare, riprova')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteDocument(UserDocument document) async {
    setState(() => _documents = _documents.where((d) => d.id != document.id).toList());

    try {
      await _documentService.deleteDocument(document);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile eliminare, riprova')));
      await _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          PageHeader(
            eyebrow: 'Tuo, solo se vuoi',
            title: 'Profilo',
            subtitle: 'Tutto qui è opzionale. Più segnali = suggerimenti più rilevanti — ma non devi nulla.\n$email',
          ),
          const SizedBox(height: 24),
          Text('NICKNAME', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'Usato per il saluto in Oggi — "Buongiorno, [nickname]".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveNickname(),
            decoration: InputDecoration(
              hintText: 'Es. Enkida',
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: _saveNickname,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('ASPETTO', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'Automatico segue l\'ora in una curva continua: luce al risveglio, '
            'sospeso nel pomeriggio, notte la sera.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Chiaro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Scuro')),
              ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
            ],
            selected: {_settings.themeMode},
            onSelectionChanged: (selection) => _setThemeMode(selection.first),
          ),
          const SizedBox(height: 24),
          Text('APPROCCIO AL BENESSERE', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'Pesa i consigli dell\'AI: più naturale (es. zenzero, EVOO, golden milk) '
            'o più mirato/da ricerca (es. integratori specifici come NAD+).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<WellnessApproach>(
            segments: const [
              ButtonSegment(value: WellnessApproach.natural, label: Text('Naturale')),
              ButtonSegment(value: WellnessApproach.balanced, label: Text('Bilanciato')),
              ButtonSegment(value: WellnessApproach.scientific, label: Text('Scientifico')),
            ],
            selected: {_settings.approach},
            onSelectionChanged: (selection) => _setApproach(selection.first),
          ),
          const SizedBox(height: 24),
          Text('SESSO', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'Opzionale — decide solo se mostrare il tracking del ciclo mestruale in Oggi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<UserSex>(
            segments: const [
              ButtonSegment(value: UserSex.unspecified, label: Text('Non specificato')),
              ButtonSegment(value: UserSex.female, label: Text('Donna')),
              ButtonSegment(value: UserSex.male, label: Text('Uomo')),
            ],
            selected: {_settings.sex},
            onSelectionChanged: (selection) => _setSex(selection.first),
          ),
          const SizedBox(height: 24),
          Text('DIGIUNO', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'Opzionale — mostra il tracking del digiuno in Oggi solo se attivato.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Traccia digiuno'),
            value: _settings.fastingEnabled,
            onChanged: _setFastingEnabled,
          ),
          const SizedBox(height: 24),
          Text('LINGUA', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'Per ora traduce Oggi e il Ritual — il resto arriva a breve.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
          const SizedBox(height: 24),
          Text('RITUALE SERALE', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'Suggerisce quando iniziare la routine serale in Oggi.',
            style: Theme.of(context).textTheme.bodySmall,
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
          const SizedBox(height: 24),
          Text('DATA DI NASCITA', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'Opzionale — serve solo per calcolare l\'età biologica stimata (PhenoAge) da un referto '
            'del sangue caricato qui sotto. Senza data di nascita, quella stima non può essere calcolata.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickBirthDate,
            child: Text(
              _settings.birthDate == null
                  ? 'Imposta data di nascita'
                  : _formatDate(_settings.birthDate!),
            ),
          ),
          const SizedBox(height: 24),
          Text('DOCUMENTI PER L\'AI', style: Theme.of(context).textTheme.labelMedium),
          Text(
            'PDF o foto (es. referto nutrizionale o del sangue) che il Focus del giorno può leggere.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _documentsLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: _documents
                      .map((doc) => AppCard(blur: 0, padding: EdgeInsets.zero, 
                            child: ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: Text(doc.label),
                              subtitle: Text(_formatDate(doc.uploadedAt)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteDocument(doc),
                              ),
                            ),
                          ))
                      .toList(),
                ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickAndUploadDocument,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: const Text('Carica documento'),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
