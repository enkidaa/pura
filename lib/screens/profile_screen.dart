import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_theme.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
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
  final _narrativeSummaryController = TextEditingController();

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
    _narrativeSummaryController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.loadSettings();
      setState(() {
        _settings = settings;
        _nicknameController.text = settings.nickname ?? '';
        _narrativeSummaryController.text = settings.narrativeSummary ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // copyWith's `newValue ?? oldValue` pattern can't express "clear this
  // field" — passing null there just keeps the old value showing locally
  // until the next reload, even though the save itself (below, called
  // directly with the trimmed value) writes the correct null. These two
  // fields are the only ones a user can blank out entirely, so their
  // optimistic update builds the next AppSettings by hand instead.
  Future<void> _saveNickname() async {
    final trimmed = _nicknameController.text.trim();
    final nickname = trimmed.isEmpty ? null : trimmed;
    setState(() => _settings = AppSettings(
          themeMode: _settings.themeMode,
          language: _settings.language,
          eveningRitualTime: _settings.eveningRitualTime,
          approach: _settings.approach,
          sex: _settings.sex,
          fastingEnabled: _settings.fastingEnabled,
          nickname: nickname,
          birthDate: _settings.birthDate,
          narrativeSummary: _settings.narrativeSummary,
          onboardingCompleted: _settings.onboardingCompleted,
        ));
    await _save(() => _settingsService.saveNickname(nickname));
  }

  Future<void> _saveNarrativeSummary() async {
    final trimmed = _narrativeSummaryController.text.trim();
    final summary = trimmed.isEmpty ? null : trimmed;
    setState(() => _settings = AppSettings(
          themeMode: _settings.themeMode,
          language: _settings.language,
          eveningRitualTime: _settings.eveningRitualTime,
          approach: _settings.approach,
          sex: _settings.sex,
          fastingEnabled: _settings.fastingEnabled,
          nickname: _settings.nickname,
          birthDate: _settings.birthDate,
          narrativeSummary: summary,
          onboardingCompleted: _settings.onboardingCompleted,
        ));
    await _save(() => _settingsService.saveNarrativeSummary(summary));
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
      helpText: AppStrings.of(context).suggerisciIlRitualeSeraleDopoLe,
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
      helpText: AppStrings.of(context).dataDiNascitaPicker,
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
          .showSnackBar(SnackBar(content: Text(AppStrings.of(context).impossibileSalvareRiprova)));
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
    } on DocumentValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.of(context).impossibileCaricareRiprova)));
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
          .showSnackBar(SnackBar(content: Text(AppStrings.of(context).impossibileEliminareRiprova)));
      await _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final strings = AppStrings.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          PageHeader(
            eyebrow: strings.tuoSoloSeVuoi,
            title: strings.profilo,
            subtitle: strings.profiloSottotitolo(email),
          ),
          const SizedBox(height: 24),
          Text(strings.nickname, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.nicknameSpiegazione,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveNickname(),
            decoration: InputDecoration(
              hintText: strings.esEnkida,
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: _saveNickname,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(strings.aspetto, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.aspettoSpiegazione,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
          Text(strings.approccioAlBenessere, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.approccioSpiegazione,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
          Text(strings.sesso, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.sessoSpiegazione,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
          Text(strings.digiunoLabel, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.digiunoSettingSpiegazione,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.tracciaDigiuno),
            value: _settings.fastingEnabled,
            onChanged: _setFastingEnabled,
          ),
          const SizedBox(height: 24),
          Text(strings.linguaLabel, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.linguaSpiegazione,
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
          Text(strings.ritualeSerale, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.ritualeSeraleSpiegazione,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickEveningRitualTime,
            child: Text(
              _settings.eveningRitualTime == null
                  ? strings.impostaOrario
                  : strings.suggerisciDopoLe(_settings.eveningRitualTime!.format(context)),
            ),
          ),
          const SizedBox(height: 24),
          Text(strings.dataDiNascitaLabel, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.dataDiNascitaSpiegazione,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickBirthDate,
            child: Text(
              _settings.birthDate == null
                  ? strings.impostaDataDiNascita
                  : _formatDate(_settings.birthDate!),
            ),
          ),
          const SizedBox(height: 24),
          Text(strings.contestoSalute, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.contestoSaluteSpiegazione,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _narrativeSummaryController,
            maxLines: 3,
            onEditingComplete: _saveNarrativeSummary,
            onTapOutside: (_) => _saveNarrativeSummary(),
            decoration: InputDecoration(hintText: strings.esContestoSalute),
          ),
          const SizedBox(height: 24),
          Text(strings.documentiPerLai, style: Theme.of(context).textTheme.labelMedium),
          Text(
            strings.documentiSpiegazione,
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
            label: Text(strings.caricaDocumento),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => AuthService().signOut(),
            child: Text(strings.esci),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
