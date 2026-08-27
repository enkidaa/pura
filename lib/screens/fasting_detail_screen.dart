import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/catalog_source.dart';
import '../models/fasting_log.dart';
import '../services/fasting_service.dart';
import '../services/notification_service.dart';
import '../services/routine_progress_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/ios_time_picker_sheet.dart';

// Reuses the generic routine_step_notes/sources tables (keyed by a plain
// text id) instead of a dedicated fasting_notes table — same shape, no
// need for another migration.
const _fastingStepId = 'fasting';
const _fastingNotificationOwnerId = 'fasting_window';
const _eatingWindow = Duration(hours: 8);
const _notificationLeadTime = Duration(hours: 7, minutes: 30);

const _fastingSources = [
  CatalogSource(
    title: 'Research on intermittent fasting shows health benefits (National Institute on Aging — NIH)',
    url: 'https://www.nia.nih.gov/news/research-intermittent-fasting-shows-health-benefits',
  ),
  CatalogSource(
    title: 'Is time-restricted eating (8/16) beneficial for body weight and metabolism? Systematic review and meta-analysis of RCTs (NIH/PMC)',
    url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10002957/',
    note: 'Benefici reali ma modesti (peso, massa grassa, glicemia) soprattutto in adulti in sovrappeso — studi brevi e campioni piccoli. Non è un intervento provato o universale.',
  ),
];

class FastingDetailScreen extends StatefulWidget {
  const FastingDetailScreen({super.key});

  @override
  State<FastingDetailScreen> createState() => _FastingDetailScreenState();
}

class _FastingDetailScreenState extends State<FastingDetailScreen> {
  final _fastingService = FastingService();
  final _progressService = RoutineProgressService();
  final _settingsService = SettingsService();
  final _noteController = TextEditingController();
  final _sourceController = TextEditingController();

  bool _loading = true;
  bool _inRoutine = false;
  FastingLog _log = const FastingLog();
  List<RoutineStepSource> _sources = [];
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps the elapsed/countdown text moving without needing any other
    // interaction — the underlying data only changes on mark/edit, this
    // just re-renders against DateTime.now().
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _noteController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _fastingService.loadCurrent(),
        _progressService.loadNote(_fastingStepId),
        _progressService.loadSources(_fastingStepId),
      ]);
      final settings = await _settingsService.loadSettings();
      if (!mounted) return;
      setState(() {
        _log = results[0] as FastingLog;
        _noteController.text = results[1] as String;
        _sources = results[2] as List<RoutineStepSource>;
        _inRoutine = settings.fastingEnabled;
        _loading = false;
      });
      await _syncNotification();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRoutine(bool value) async {
    setState(() => _inRoutine = value);
    try {
      await _settingsService.saveFastingEnabled(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _inRoutine = !value);
    }
  }

  /// One button, one action: marks whichever event ends the *current*
  /// phase (first meal if fasting, last meal if eating) with the tap's own
  /// timestamp — this is the entire fasting/eating toggle.
  Future<void> _toggleMeal() async {
    final previous = _log;
    final wasEating = _log.isEating;
    final now = DateTime.now();
    setState(() {
      _log = FastingLog(
        firstMealTime: wasEating ? _log.firstMealTime : now,
        lastMealTime: wasEating ? now : _log.lastMealTime,
      );
    });
    try {
      if (wasEating) {
        await _fastingService.markLastMeal(now, closingEatingStart: previous.firstMealTime);
      } else {
        await _fastingService.markFirstMeal(now, closingFastStart: previous.lastMealTime);
      }
      await _syncNotification();
    } catch (_) {
      if (!mounted) return;
      setState(() => _log = previous);
    }
  }

  /// Lets a mis-timed tap be corrected after the fact — same phase, just a
  /// different timestamp, keeping the existing calendar day so a fast that
  /// already spans midnight doesn't get accidentally shifted a day.
  Future<void> _editCurrentPhaseTime() async {
    final strings = AppStrings.of(context);
    final isEating = _log.isEating;
    final currentStart = _log.currentPhaseStart ?? DateTime.now();
    final picked = await showIosTimePickerSheet(
      context: context,
      title: isEating ? strings.aCheOraHaiIniziatoAMangiare : strings.aCheOraHaiFinitoDiMangiare,
      initialTime: TimeOfDay.fromDateTime(currentStart),
    );
    if (picked == null || !mounted) return;

    final corrected = DateTime(
      currentStart.year,
      currentStart.month,
      currentStart.day,
      picked.hour,
      picked.minute,
    );
    final previous = _log;
    setState(() {
      _log = FastingLog(
        firstMealTime: isEating ? corrected : _log.firstMealTime,
        lastMealTime: isEating ? _log.lastMealTime : corrected,
      );
    });
    try {
      if (isEating) {
        await _fastingService.markFirstMeal(corrected);
      } else {
        await _fastingService.markLastMeal(corrected);
      }
      await _syncNotification();
    } catch (_) {
      if (!mounted) return;
      setState(() => _log = previous);
    }
  }

  /// Keeps the "window closing soon" notification in lockstep with the
  /// actual state: scheduled 7h30 after the first meal while eating,
  /// cancelled the moment the last meal is marked (or the state isn't
  /// eating at all) — that cancellation is what "stops the timer".
  Future<void> _syncNotification() async {
    if (_log.isEating && _log.firstMealTime != null) {
      final strings = AppStrings.of(context);
      await NotificationService.scheduleOneOff(
        ownerId: _fastingNotificationOwnerId,
        title: strings.notificaFinestraDigiunoTitolo,
        body: strings.notificaFinestraDigiunoBody,
        at: _log.firstMealTime!.add(_notificationLeadTime),
      );
    } else {
      await NotificationService.cancelOneOff(_fastingNotificationOwnerId);
    }
  }

  Future<void> _saveNote() async {
    try {
      await _progressService.saveNote(_fastingStepId, _noteController.text.trim());
    } catch (_) {
      // Non-blocking.
    }
  }

  Future<void> _addSource() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) return;
    _sourceController.clear();
    try {
      await _progressService.addSource(_fastingStepId, text);
      final sources = await _progressService.loadSources(_fastingStepId);
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

  String _formatDuration(Duration d) => '${d.inHours}h ${d.inMinutes.remainder(60)}m';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

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
                  Text(strings.finestraDiDigiunoEyebrow, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Text(strings.finestraDiDigiuno, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(_log.isEating ? strings.obiettivo8hChip : strings.obiettivo16hChip),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    blur: 0,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.nellaMiaRoutine),
                      subtitle: Text(strings.mostraFinestraDigiunoInOggi),
                      value: _inRoutine,
                      onChanged: _toggleRoutine,
                    ),
                  ),
                  AppCard(
                    blur: 0,
                    child: Builder(builder: (context) {
                      final phaseStart = _log.currentPhaseStart;
                      final elapsed = phaseStart == null ? null : DateTime.now().difference(phaseStart);
                      final remaining = _log.isEating && elapsed != null ? _eatingWindow - elapsed : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            elapsed == null
                                ? '—'
                                : (_log.isEating
                                    ? strings.inPastoDa(_formatDuration(elapsed))
                                    : strings.inDigiunoDa(_formatDuration(elapsed))),
                            style: theme.textTheme.headlineSmall,
                          ),
                          if (remaining != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              remaining.isNegative
                                  ? strings.finestraChiusa
                                  : strings.finestraSiChiudeTra(_formatDuration(remaining)),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: remaining.inMinutes <= 30 ? theme.colorScheme.error : null,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: _toggleMeal,
                            child: Text(_log.isEating ? strings.segnaUltimoPasto : strings.segnaPrimoPasto),
                          ),
                          if (phaseStart != null) ...[
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                onPressed: _editCurrentPhaseTime,
                                child: Text(strings.correggiOrario),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                  ),
                  Text(strings.info, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  Text(
                    strings.digiunoSpiegazione,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(strings.fontiScientifiche, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  ..._fastingSources.map((s) => Padding(
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
