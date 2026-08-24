import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/catalog_source.dart';
import '../models/fasting_log.dart';
import '../services/fasting_service.dart';
import '../services/routine_progress_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_card.dart';

// Reuses the generic routine_step_notes/sources tables (keyed by a plain
// text id) instead of a dedicated fasting_notes table — same shape, no
// need for another migration.
const _fastingStepId = 'fasting';

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
        _fastingService.loadToday(),
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

  Future<void> _markMeal({required bool isFirstMeal}) async {
    final previous = _log;
    final now = DateTime.now();
    setState(() {
      _log = FastingLog(
        firstMealTime: isFirstMeal ? now : _log.firstMealTime,
        lastMealTime: isFirstMeal ? _log.lastMealTime : now,
      );
    });
    try {
      if (isFirstMeal) {
        await _fastingService.markFirstMealNow();
      } else {
        await _fastingService.markLastMealNow();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _log = previous);
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
                  Text('DIGIUNO', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Text('Finestra di digiuno', style: theme.textTheme.displaySmall),
                  const SizedBox(height: 10),
                  Chip(label: const Text('Obiettivo 16h'), visualDensity: VisualDensity.compact),
                  const SizedBox(height: 20),
                  AppCard(
                    blur: 0,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Nella mia routine'),
                      subtitle: const Text('Mostra la finestra di digiuno in Oggi'),
                      value: _inRoutine,
                      onChanged: _toggleRoutine,
                    ),
                  ),
                  AppCard(
                    blur: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _log.lastMealTime == null
                              ? '—'
                              : 'In digiuno da ${_formatDuration(DateTime.now().difference(_log.lastMealTime!))}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _markMeal(isFirstMeal: false),
                                child: const Text('Segna ultimo pasto'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _markMeal(isFirstMeal: true),
                                child: const Text('Segna primo pasto'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text('INFO', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  Text(
                    'Finestra 16:8 — mangi in una fascia di 8 ore, digiuni per le restanti 16. '
                    'Segna l\'ultimo pasto di ieri e il primo di oggi per tracciare la finestra.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text('FONTI SCIENTIFICHE', style: theme.textTheme.labelMedium),
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
                  Text('LE TUE FONTI', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  if (_sources.isEmpty)
                    Text(
                      'Nessuna fonte ancora. Aggiungine una qui sotto — è solo per te.',
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
                          decoration: const InputDecoration(hintText: 'Aggiungi una fonte...'),
                          onSubmitted: (_) => _addSource(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(icon: const Icon(Icons.add), onPressed: _addSource),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('NOTE PERSONALI', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    onEditingComplete: _saveNote,
                    onTapOutside: (_) => _saveNote(),
                    decoration: const InputDecoration(hintText: 'Le tue note...'),
                  ),
                ],
              ),
      ),
    );
  }
}
