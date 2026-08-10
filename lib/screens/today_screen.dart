import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/cycle_info.dart';
import '../models/fasting_log.dart';
import '../models/focus_suggestion.dart';
import '../models/routine_step.dart';
import '../models/sleep_log.dart';
import '../services/cycle_service.dart';
import '../services/fasting_service.dart';
import '../services/focus_service.dart';
import '../services/health_service.dart';
import '../services/plant_diversity_service.dart';
import '../services/routine_progress_service.dart';
import '../services/settings_service.dart';
import '../services/skincare_photo_service.dart';
import '../services/sleep_service.dart';
import '../services/sound_link_service.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _progressService = RoutineProgressService();
  final _plantService = PlantDiversityService();
  final _sleepService = SleepService();
  final _fastingService = FastingService();
  final _soundLinkService = SoundLinkService();
  final _skincareService = SkincarePhotoService();

  Set<String> _completedStepIds = {};
  bool _routineLoading = true;

  Set<String> _plants = {};
  bool _plantsLoading = true;

  SleepLog? _sleepLog;
  bool _sleepLoading = true;
  List<SleepLog> _recentSleepLogs = [];

  FastingLog _fastingLog = const FastingLog();
  bool _fastingLoading = true;

  String? _soundUrl;
  bool _soundLoading = true;

  Map<SkincarePeriod, String> _skincarePhotos = {};
  bool _skincareLoading = true;

  final _focusService = FocusService();
  FocusSuggestion? _focusSuggestion;
  String? _focusError;
  bool _focusLoading = false;

  final _settingsService = SettingsService();
  final _cycleService = CycleService();
  UserSex _userSex = UserSex.unspecified;
  CycleInfo? _cycleInfo;
  bool _cycleLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadPlants();
    _loadSleep();
    _loadSleepRegularity();
    _loadFasting();
    _loadSound();
    _loadSkincare();
    _loadCycleIfRelevant();
  }

  Future<void> _loadCycleIfRelevant() async {
    try {
      final settings = await _settingsService.loadSettings();
      if (settings.sex != UserSex.female) {
        if (mounted) setState(() => _cycleLoading = false);
        return;
      }
      final info = await _cycleService.loadCycleInfo();
      setState(() {
        _userSex = settings.sex;
        _cycleInfo = info;
        _cycleLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cycleLoading = false);
    }
  }

  Future<void> _logPeriodStartToday() async {
    final previous = _cycleInfo;
    try {
      await _cycleService.logPeriodStart(DateTime.now());
      final info = await _cycleService.loadCycleInfo();
      if (!mounted) return;
      setState(() => _cycleInfo = info);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cycleInfo = previous);
      _showError('Impossibile salvare, riprova');
    }
  }

  Future<void> _loadProgress() async {
    try {
      final completed = await _progressService.loadCompletedToday();
      setState(() {
        _completedStepIds = completed;
        _routineLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _routineLoading = false);
    }
  }

  Future<void> _toggleStep(RoutineStep step, bool completed) async {
    setState(() {
      if (completed) {
        _completedStepIds.add(step.id);
      } else {
        _completedStepIds.remove(step.id);
      }
    });

    try {
      await _progressService.setStepCompleted(step.id, completed);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (completed) {
          _completedStepIds.remove(step.id);
        } else {
          _completedStepIds.add(step.id);
        }
      });
      _showError('Impossibile salvare, riprova');
    }
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await _plantService.loadUniquePlantsThisWeek();
      setState(() {
        _plants = plants;
        _plantsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _plantsLoading = false);
    }
  }

  Future<void> _addPlant(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _plants.contains(trimmed)) return;

    setState(() => _plants = {..._plants, trimmed});

    try {
      await _plantService.logPlant(trimmed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _plants = _plants.where((p) => p != trimmed).toSet());
      _showError('Impossibile salvare, riprova');
    }
  }

  Future<void> _loadSleep() async {
    try {
      final log = await _sleepService.loadLastNight();
      setState(() {
        _sleepLog = log;
        _sleepLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _sleepLoading = false);
    }
  }

  Future<void> _loadSleepRegularity() async {
    try {
      final logs = await _sleepService.loadRecentSleepLogs();
      if (mounted) setState(() => _recentSleepLogs = logs);
    } catch (_) {
      // Non-critical: the main sleep card still works without this.
    }
  }

  // Range (max-min) of wake times across recent nights, in minutes —
  // a simple, explainable proxy for circadian regularity. Needs at least
  // 2 nights to say anything.
  int? _wakeTimeVariabilityMinutes() {
    if (_recentSleepLogs.length < 2) return null;
    final minutesOfDay = _recentSleepLogs
        .map((log) => log.wakeTime.hour * 60 + log.wakeTime.minute)
        .toList();
    return minutesOfDay.reduce((a, b) => a > b ? a : b) -
        minutesOfDay.reduce((a, b) => a < b ? a : b);
  }

  Future<void> _saveSleep(DateTime bedtime, DateTime wakeTime) async {
    final previous = _sleepLog;
    setState(() => _sleepLog = SleepLog(bedtime: bedtime, wakeTime: wakeTime));

    try {
      await _sleepService.saveLastNight(bedtime: bedtime, wakeTime: wakeTime);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sleepLog = previous);
      _showError('Impossibile salvare, riprova');
    }
  }

  Future<void> _loadFasting() async {
    try {
      final log = await _fastingService.loadToday();
      setState(() {
        _fastingLog = log;
        _fastingLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _fastingLoading = false);
    }
  }

  Future<void> _markMeal({required bool isFirstMeal}) async {
    final previous = _fastingLog;
    final now = DateTime.now();
    setState(() {
      _fastingLog = FastingLog(
        firstMealTime: isFirstMeal ? now : _fastingLog.firstMealTime,
        lastMealTime: isFirstMeal ? _fastingLog.lastMealTime : now,
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
      setState(() => _fastingLog = previous);
      _showError('Impossibile salvare, riprova');
    }
  }

  Future<void> _loadSound() async {
    try {
      final url = await _soundLinkService.loadToday();
      setState(() {
        _soundUrl = url;
        _soundLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _soundLoading = false);
    }
  }

  Future<void> _saveSound(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    final previous = _soundUrl;
    setState(() => _soundUrl = trimmed);

    try {
      await _soundLinkService.saveToday(trimmed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _soundUrl = previous);
      _showError('Impossibile salvare, riprova');
    }
  }

  Future<void> _loadSkincare() async {
    try {
      final photos = await _skincareService.loadTodaySignedUrls();
      setState(() {
        _skincarePhotos = photos;
        _skincareLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _skincareLoading = false);
    }
  }

  Future<void> _takeSkincarePhoto(SkincarePeriod period) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;

    try {
      await _skincareService.uploadPhoto(period, File(picked.path));
      await _loadSkincare();
    } catch (_) {
      if (!mounted) return;
      _showError('Impossibile salvare la foto, riprova');
    }
  }

  Future<void> _generateFocus() async {
    setState(() {
      _focusLoading = true;
      _focusError = null;
    });

    try {
      final suggestion = await _focusService.getFocusDelGiorno();
      setState(() {
        _focusSuggestion = suggestion;
        _focusLoading = false;
      });
    } catch (e) {
      setState(() {
        _focusError = 'Impossibile generare il consiglio, riprova';
        _focusLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddPlantDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi una pianta'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Es. broccoli'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    if (name != null) _addPlant(name);
  }

  Future<void> _importSleepFromHealth() async {
    final healthService = HealthService();
    final authorized = await healthService.requestAuthorization();
    if (!authorized) {
      if (!mounted) return;
      _showError('Permesso Salute negato');
      return;
    }

    final log = await healthService.fetchLastNightSleep();
    if (log == null) {
      if (!mounted) return;
      _showError('Nessun dato sonno trovato in Salute');
      return;
    }

    _saveSleep(log.bedtime, log.wakeTime);
  }

  Future<void> _showSleepDialog() async {
    var bedtime = _sleepLog != null
        ? TimeOfDay.fromDateTime(_sleepLog!.bedtime)
        : const TimeOfDay(hour: 23, minute: 0);
    var wakeTime = _sleepLog != null
        ? TimeOfDay.fromDateTime(_sleepLog!.wakeTime)
        : const TimeOfDay(hour: 7, minute: 0);

    final pickedBedtime = await showTimePicker(
      context: context,
      initialTime: bedtime,
      helpText: 'A che ora sei andato a letto?',
    );
    if (pickedBedtime == null) return;
    bedtime = pickedBedtime;

    if (!mounted) return;
    final pickedWakeTime = await showTimePicker(
      context: context,
      initialTime: wakeTime,
      helpText: 'A che ora ti sei svegliato?',
    );
    if (pickedWakeTime == null) return;
    wakeTime = pickedWakeTime;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final bedtimeDate = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
      bedtime.hour,
      bedtime.minute,
    );
    final wakeTimeDate = DateTime(
      today.year,
      today.month,
      today.day,
      wakeTime.hour,
      wakeTime.minute,
    );

    _saveSleep(bedtimeDate, wakeTimeDate);
  }

  Future<void> _showSoundLinkDialog() async {
    final controller = TextEditingController(text: _soundUrl ?? '');
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link per oggi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'Link Spotify, Apple Music o podcast',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (url != null) _saveSound(url);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Focus del giorno'),
          const SizedBox(height: 16),
          _buildFocusCard(),
          const SizedBox(height: 32),
          _sectionTitle('Routine mattutina'),
          const SizedBox(height: 16),
          if (_routineLoading)
            const Center(child: CircularProgressIndicator())
          else
            ...morningRoutineSteps.map((step) {
              final isCompleted = _completedStepIds.contains(step.id);
              return Card(
                child: CheckboxListTile(
                  value: isCompleted,
                  onChanged: (value) => _toggleStep(step, value ?? false),
                  title: Text(step.title),
                  subtitle: Text('${step.durationMinutes} min'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }),
          const SizedBox(height: 32),
          _sectionTitle('Diversità vegetale'),
          const SizedBox(height: 16),
          _buildPlantCard(),
          const SizedBox(height: 32),
          _sectionTitle('Sonno'),
          const SizedBox(height: 16),
          _buildSleepCard(),
          const SizedBox(height: 32),
          _sectionTitle('Digiuno'),
          const SizedBox(height: 16),
          _buildFastingCard(),
          const SizedBox(height: 32),
          if (_userSex == UserSex.female) ...[
            _sectionTitle('Ciclo mestruale'),
            const SizedBox(height: 16),
            _buildCycleCard(),
            const SizedBox(height: 32),
          ],
          _sectionTitle('Prodotti skincare'),
          const SizedBox(height: 16),
          _buildSkincareCard(),
          const SizedBox(height: 32),
          _sectionTitle('Suoni'),
          const SizedBox(height: 16),
          _buildSoundCard(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: Theme.of(context).textTheme.headlineSmall);
  }

  Widget _buildFocusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_focusLoading)
              const Center(child: CircularProgressIndicator())
            else if (_focusError != null)
              Text(
                _focusError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_focusSuggestion != null)
              _buildFocusSuggestion(_focusSuggestion!)
            else
              const Text('Ancora nessun consiglio per oggi.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _focusLoading ? null : _generateFocus,
              child: const Text('Genera consiglio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusSuggestion(FocusSuggestion suggestion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          suggestion.recommendation,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          suggestion.observation,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Chip(
              label: Text('affidabilità: ${suggestion.confidence}'),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text('evidenza: ${suggestion.evidenceStrength}'),
              visualDensity: VisualDensity.compact,
            ),
            if (suggestion.sources.isNotEmpty)
              Chip(
                label: Text('fonti: ${suggestion.sources.join(", ")}'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlantCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _plantsLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_plants.length} / 30 piante questa settimana',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _showAddPlantDialog,
                      ),
                    ],
                  ),
                  if (_plants.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _plants.map((plant) => Chip(label: Text(plant))).toList(),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSleepCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _sleepLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sleepLog == null
                                  ? 'Notte scorsa — non ancora registrata'
                                  : _formatDuration(_sleepLog!.duration),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Text('Obiettivo 9h'),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: _showSleepDialog,
                        child: Text(_sleepLog == null ? 'Registra' : 'Modifica'),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _importSleepFromHealth,
                    icon: const Icon(Icons.favorite_outline, size: 18),
                    label: const Text('Importa da Salute'),
                  ),
                  if (_wakeTimeVariabilityMinutes() != null) ...[
                    const Divider(height: 24),
                    Text(
                      'Ritmo circadiano',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sveglia variabile di ${_formatDuration(Duration(minutes: _wakeTimeVariabilityMinutes()!))} '
                      'negli ultimi ${_recentSleepLogs.length} giorni tracciati.',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildFastingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _fastingLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fastingLog.lastMealTime == null
                        ? 'Finestra di digiuno — non ancora tracciata'
                        : 'In digiuno da ${_formatDuration(DateTime.now().difference(_fastingLog.lastMealTime!))}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text('Obiettivo 16h'),
                  const SizedBox(height: 12),
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
    );
  }

  Widget _buildCycleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _cycleLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cycleInfo == null
                        ? 'Ciclo — non ancora tracciato'
                        : 'Giorno ${_cycleInfo!.cycleDay} · fase ${_phaseLabel(_cycleInfo!.phase)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_cycleInfo != null)
                    Text(
                      'Prossimo ciclo stimato: ${_formatDate(_cycleInfo!.predictedNextStart)} '
                      '(ciclo medio ${_cycleInfo!.avgCycleLength}gg)',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _logPeriodStartToday,
                    child: const Text('Segna inizio ciclo oggi'),
                  ),
                ],
              ),
      ),
    );
  }

  String _phaseLabel(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'mestruale';
      case CyclePhase.follicular:
        return 'follicolare';
      case CyclePhase.ovulation:
        return 'ovulazione';
      case CyclePhase.luteal:
        return 'luteale';
    }
  }

  Widget _buildSkincareCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _skincareLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  Expanded(child: _skincareSlot(SkincarePeriod.mattino, 'Mattino')),
                  const SizedBox(width: 16),
                  Expanded(child: _skincareSlot(SkincarePeriod.sera, 'Sera')),
                ],
              ),
      ),
    );
  }

  Widget _skincareSlot(SkincarePeriod period, String label) {
    final url = _skincarePhotos[period];
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _takeSkincarePhoto(period),
          child: Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              image: url == null
                  ? null
                  : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            ),
            child: url == null
                ? const Icon(Icons.camera_alt_outlined)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSoundCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _soundLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _soundUrl == null
                        ? const Text('Nessun link per oggi')
                        : InkWell(
                            onTap: () =>
                                launchUrl(Uri.parse(_soundUrl!)),
                            child: Text(
                              _soundUrl!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: _showSoundLinkDialog,
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
