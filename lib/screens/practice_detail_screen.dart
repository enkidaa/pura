import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/practice.dart';
import '../models/schedule_spec.dart';
import '../services/practice_service.dart';
import '../services/routine_progress_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/evidence_badge.dart';
import '../widgets/schedule_editor.dart';

class PracticeDetailScreen extends StatefulWidget {
  const PracticeDetailScreen({super.key, required this.practice});

  final Practice practice;

  @override
  State<PracticeDetailScreen> createState() => _PracticeDetailScreenState();
}

class _PracticeDetailScreenState extends State<PracticeDetailScreen> {
  final _practiceService = PracticeService();
  final _progressService = RoutineProgressService();
  final _settingsService = SettingsService();
  final _noteController = TextEditingController();
  final _sourceController = TextEditingController();

  bool _loading = true;
  bool _inRoutine = false;
  WellnessApproach _approach = WellnessApproach.balanced;
  List<RoutineStepSource> _sources = [];
  ScheduleSpec _schedule = const ScheduleSpec();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _practiceService.loadRoutinePracticeIds(),
        _progressService.loadNote(widget.practice.id),
        _progressService.loadSources(widget.practice.id),
        _settingsService.loadSettings(),
        _practiceService.loadSchedule(widget.practice.id),
      ]);
      if (!mounted) return;
      setState(() {
        _inRoutine = (results[0] as Set<String>).contains(widget.practice.id);
        _noteController.text = results[1] as String;
        _sources = results[2] as List<RoutineStepSource>;
        _approach = (results[3] as AppSettings).approach;
        _schedule = results[4] as ScheduleSpec;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRoutine(bool value) async {
    setState(() {
      _inRoutine = value;
      if (value) _schedule = const ScheduleSpec();
    });
    try {
      if (value) {
        await _practiceService.addToRoutine(widget.practice.id);
      } else {
        await _practiceService.removeFromRoutine(widget.practice.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _inRoutine = !value);
    }
  }

  Future<void> _updateSchedule(ScheduleSpec spec) async {
    setState(() => _schedule = spec);
    try {
      await _practiceService.saveSchedule(widget.practice.id, spec);
    } catch (_) {
      // Non-blocking — user can retry by re-selecting.
    }
  }

  Future<void> _saveNote() async {
    try {
      await _progressService.saveNote(widget.practice.id, _noteController.text.trim());
    } catch (_) {
      // Non-blocking.
    }
  }

  Future<void> _addSource() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) return;
    _sourceController.clear();
    try {
      await _progressService.addSource(widget.practice.id, text);
      final sources = await _progressService.loadSources(widget.practice.id);
      if (mounted) setState(() => _sources = sources);
    } catch (_) {
      // Silent.
    }
  }

  Future<void> _removeSource(String id) async {
    final previous = _sources;
    setState(() => _sources = _sources.where((s) => s.id != id).toList());
    try {
      await _progressService.removeSource(id);
    } catch (_) {
      if (mounted) setState(() => _sources = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final practice = widget.practice;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 8),
                  Text(practiceCategoryLabel(practice.category, strings).toUpperCase(),
                      style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Text(practice.name, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(practice.frequency), visualDensity: VisualDensity.compact),
                      EvidenceBadge(level: practice.evidenceLevel),
                      if (practice.matchesApproach(_approach))
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(Icons.tune, size: 14, color: theme.colorScheme.primary),
                          label: Text(strings.allineatoAlTuoApproccio),
                          labelStyle: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    blur: 0,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.nellaMiaRoutine),
                      value: _inRoutine,
                      onChanged: _toggleRoutine,
                    ),
                  ),
                  if (_inRoutine)
                    AppCard(
                      blur: 0,
                      child: ScheduleEditor(spec: _schedule, onChanged: _updateSchedule),
                    ),
                  Text(strings.descrizione, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  Text(practice.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  Text(strings.obiettivo, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  Text(practice.goal, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  Text(strings.beneficiPossibili, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  Text(practice.benefits, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  Text(strings.comeIniziare, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  Text(practice.howToStart, style: theme.textTheme.bodyLarge),
                  if (practice.risks != null) ...[
                    const SizedBox(height: 20),
                    Text(strings.rischiEControindicazioni, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 10),
                    Text(practice.risks!, style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: 24),
                  Text(strings.fontiScientifiche, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  if (practice.sources.isEmpty)
                    Text(
                      strings.nessunaFonteVerificataAncora,
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    ...practice.sources.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () =>
                                    launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication),
                                child: Text(
                                  s.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              if (s.note != null) ...[
                                const SizedBox(height: 4),
                                Text(s.note!, style: theme.textTheme.bodySmall),
                              ],
                            ],
                          ),
                        )),
                  const SizedBox(height: 8),
                  Text(strings.leTueFonti, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  if (_sources.isEmpty)
                    Text(
                      strings.nessunaFonteAncora,
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    ..._sources.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(s.text, style: theme.textTheme.bodyMedium)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _removeSource(s.id),
                              ),
                            ],
                          ),
                        )),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sourceController,
                          decoration: InputDecoration(hintText: strings.aggiungiUnaFonte),
                          onSubmitted: (_) => _addSource(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(icon: const Icon(Icons.add), onPressed: _addSource),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(strings.notePersonali, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    onEditingComplete: _saveNote,
                    onTapOutside: (_) => _saveNote(),
                    decoration: InputDecoration(hintText: strings.leTueNote),
                  ),
                ],
              ),
      ),
    );
  }
}
