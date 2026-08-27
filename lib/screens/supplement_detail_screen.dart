import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/schedule_spec.dart';
import '../models/supplement_catalog.dart';
import '../models/supplement_reminder.dart';
import '../services/supplement_reminder_service.dart';
import '../services/supplement_service.dart';
import '../widgets/app_card.dart';
import '../widgets/evidence_badge.dart';
import '../widgets/schedule_editor.dart';

class SupplementDetailScreen extends StatefulWidget {
  const SupplementDetailScreen({super.key, required this.item});

  final SupplementCatalogItem item;

  @override
  State<SupplementDetailScreen> createState() => _SupplementDetailScreenState();
}

class _SupplementDetailScreenState extends State<SupplementDetailScreen> {
  final _service = SupplementService();
  final _reminderService = SupplementReminderService();
  final _noteController = TextEditingController();
  final _sourceController = TextEditingController();

  bool _loading = true;
  bool _takenToday = false;
  bool _inRoutine = false;
  List<SupplementSource> _sources = [];
  SupplementReminder _reminder = const SupplementReminder(
    supplementId: '',
    weekdays: {},
    time: TimeOfDay(hour: 9, minute: 0),
    enabled: false,
  );
  bool _savingReminder = false;
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
        _service.loadTodayIntake(),
        _service.loadNote(widget.item.id),
        _service.loadSources(widget.item.id),
        _service.loadRoutineIds(),
        _reminderService.load(widget.item.id),
        _service.loadSchedule(widget.item.id),
      ]);
      if (!mounted) return;
      setState(() {
        _takenToday = (results[0] as Set<String>).contains(widget.item.id);
        _noteController.text = results[1] as String;
        _sources = results[2] as List<SupplementSource>;
        _inRoutine = (results[3] as Set<String>).contains(widget.item.id);
        _reminder = results[4] as SupplementReminder;
        _schedule = results[5] as ScheduleSpec;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleTaken(bool value) async {
    setState(() => _takenToday = value);
    try {
      await _service.setIntakeToday(widget.item.id, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _takenToday = !value);
    }
  }

  Future<void> _toggleRoutine(bool value) async {
    setState(() {
      _inRoutine = value;
      if (value) _schedule = const ScheduleSpec();
    });
    try {
      if (value) {
        await _service.addToRoutine(widget.item.id);
      } else {
        await _service.removeFromRoutine(widget.item.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _inRoutine = !value);
    }
  }

  Future<void> _updateSchedule(ScheduleSpec spec) async {
    setState(() => _schedule = spec);
    try {
      await _service.saveSchedule(widget.item.id, spec);
    } catch (_) {
      // Non-blocking — user can retry by re-selecting.
    }
  }

  Future<void> _saveReminder() async {
    setState(() => _savingReminder = true);
    try {
      await _reminderService.save(_reminder, supplementName: widget.item.name);
    } catch (_) {
      // Non-blocking — reminder stays as edited locally, user can retry save.
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }

  void _toggleReminderDay(int weekday) {
    final weekdays = Set<int>.from(_reminder.weekdays);
    if (weekdays.contains(weekday)) {
      weekdays.remove(weekday);
    } else {
      weekdays.add(weekday);
    }
    setState(() => _reminder = _reminder.copyWith(weekdays: weekdays));
    _saveReminder();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminder.time);
    if (picked == null) return;
    setState(() => _reminder = _reminder.copyWith(time: picked));
    _saveReminder();
  }

  void _toggleReminderEnabled(bool value) {
    setState(() => _reminder = _reminder.copyWith(enabled: value));
    _saveReminder();
  }

  Future<void> _saveNote() async {
    try {
      await _service.saveNote(widget.item.id, _noteController.text.trim());
    } catch (_) {
      // Non-blocking — the field just keeps the unsaved text locally.
    }
  }

  Future<void> _addSource() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) return;
    _sourceController.clear();
    try {
      await _service.addSource(widget.item.id, text);
      final sources = await _service.loadSources(widget.item.id);
      if (mounted) setState(() => _sources = sources);
    } catch (_) {
      // Silent — user can retype and retry.
    }
  }

  Future<void> _removeSource(String id) async {
    final previous = _sources;
    setState(() => _sources = _sources.where((s) => s.id != id).toList());
    try {
      await _service.removeSource(id);
    } catch (_) {
      if (mounted) setState(() => _sources = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final item = widget.item;
    final weekdayLabels = {
      for (var i = 0; i < 7; i++) i + 1: strings.weekdayLettersMonToSun[i],
    };

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
                  Text(strings.integratoriEyebrow, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Text(item.name, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(label: Text(item.frequency), visualDensity: VisualDensity.compact),
                      Chip(
                          label: Text(strings.minuti(item.durationMinutes)),
                          visualDensity: VisualDensity.compact),
                      if (item.timeOfDay != null)
                        Chip(label: Text(item.timeOfDay!), visualDensity: VisualDensity.compact),
                      EvidenceBadge(level: item.evidenceLevel),
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
                  AppCard(
                    blur: 0,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.presoOggi),
                      value: _takenToday,
                      onChanged: _toggleTaken,
                    ),
                  ),
                  if (_inRoutine)
                    AppCard(
                      blur: 0,
                      child: ScheduleEditor(spec: _schedule, onChanged: _updateSchedule),
                    ),
                  AppCard(
                    blur: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(strings.impostaPromemoria),
                          subtitle: _savingReminder ? Text(strings.salvataggioInCorso) : null,
                          value: _reminder.enabled,
                          onChanged: _toggleReminderEnabled,
                        ),
                        if (_reminder.enabled) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: weekdayLabels.entries.map((entry) {
                              final selected = _reminder.weekdays.contains(entry.key);
                              return ChoiceChip(
                                label: Text(entry.value),
                                selected: selected,
                                onSelected: (_) => _toggleReminderDay(entry.key),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _pickReminderTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_reminder.time.format(context)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(strings.benefici, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  Text(item.benefits, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  Text(strings.fontiScientifiche, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  ...item.sources.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication),
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
                  if (item.sources.isNotEmpty) const SizedBox(height: 8),
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
