import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/cycle_info.dart';
import '../models/fasting_log.dart';
import '../models/routine_step.dart';
import '../models/sleep_log.dart';
import '../services/cycle_service.dart';
import '../services/fasting_service.dart';
import '../services/health_service.dart';
import '../services/plant_diversity_service.dart';
import '../services/routine_progress_service.dart';
import '../services/settings_service.dart';
import '../services/skincare_photo_service.dart';
import '../services/sleep_service.dart';
import '../services/sound_link_service.dart';
import '../services/time_budget_service.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';
import '../widgets/ritual_orbit.dart';
import '../widgets/time_budget_prompt.dart';
import 'cycle_screen.dart';
import 'fasting_detail_screen.dart';
import 'plant_diversity_screen.dart';
import 'routine_step_detail_screen.dart';
import 'sleep_screen.dart';

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

  SleepLog? _sleepLog;
  List<SleepLog> _recentSleepLogs = [];

  FastingLog _fastingLog = const FastingLog();

  String? _soundUrl;

  Map<SkincarePeriod, String> _skincarePhotos = {};
  bool _skincareLoading = true;


  final _settingsService = SettingsService();
  final _cycleService = CycleService();
  UserSex _userSex = UserSex.unspecified;
  CycleInfo? _cycleInfo;
  bool _cycleLoading = true;
  bool _fastingEnabled = false;
  String? _nickname;
  TimeOfDay? _eveningRitualTime;

  final _timeBudgetService = TimeBudgetService();
  int? _timeBudgetMinutes;

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
    _loadTimeBudget();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptTimeBudget());
  }

  Future<void> _loadTimeBudget() async {
    try {
      final minutes = await _timeBudgetService.loadActiveBudgetMinutes();
      if (mounted) setState(() => _timeBudgetMinutes = minutes);
    } catch (_) {
      // Ritual just shows the full list if this fails.
    }
  }

  Future<void> _maybePromptTimeBudget() async {
    final hour = DateTime.now().hour;
    final String dayPart;
    if (hour < 13) {
      dayPart = 'morning';
    } else if (hour >= 19) {
      dayPart = 'evening';
    } else {
      return;
    }

    try {
      final already = await _timeBudgetService.hasPromptedToday(dayPart);
      if (already || !mounted) return;
      final minutes = await showTimeBudgetPrompt(context);
      await _timeBudgetService.savePrompt(dayPart, minutes);
      _loadTimeBudget();
    } catch (_) {
      // Non-critical — the prompt just won't show this time.
    }
  }

  /// Reorders (never hides or invents) the fixed Ritual step list: the
  /// half of the day that's actually relevant right now comes first, and
  /// within each half, steps not yet completed today surface before ones
  /// already done. Purely a deterministic client-side reordering of
  /// existing data — no AI call, nothing about completion state changes.
  List<RoutineStep> _orderedRitualSteps() {
    final now = TimeOfDay.now();
    final cutoff = _eveningRitualTime ?? const TimeOfDay(hour: 17, minute: 0);
    final pastCutoff =
        now.hour > cutoff.hour || (now.hour == cutoff.hour && now.minute >= cutoff.minute);
    final byTimeOfDay = pastCutoff
        ? [...eveningRoutineSteps, ...morningRoutineSteps]
        : [...morningRoutineSteps, ...eveningRoutineSteps];
    final pending = byTimeOfDay.where((s) => !_completedStepIds.contains(s.id)).toList();
    final done = byTimeOfDay.where((s) => _completedStepIds.contains(s.id)).toList();
    return [...pending, ...done];
  }

  List<RoutineStep> _fitToTimeBudget(List<RoutineStep> steps) {
    final budget = _timeBudgetMinutes;
    if (budget == null) return steps;

    final fitted = <RoutineStep>[];
    var total = 0;
    for (final step in steps) {
      if (total + step.durationMinutes > budget) continue;
      fitted.add(step);
      total += step.durationMinutes;
    }
    return fitted.isEmpty ? steps : fitted;
  }

  Future<void> _loadCycleIfRelevant() async {
    try {
      final settings = await _settingsService.loadSettings();
      setState(() {
        _fastingEnabled = settings.fastingEnabled;
        _nickname = settings.nickname;
        _eveningRitualTime = settings.eveningRitualTime;
      });

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
      _showError(AppStrings.of(context).impossibileSalvareRiprova);
    }
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await _plantService.loadUniquePlantsThisWeek();
      if (mounted) setState(() => _plants = plants);
    } catch (_) {
      // Row falls back to defaults if this fails.
    }
  }

  Future<void> _loadSleep() async {
    try {
      final log = await _sleepService.loadLastNight();
      if (mounted) setState(() => _sleepLog = log);
    } catch (_) {
      // Row falls back to defaults if this fails.
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
  // Smallest arc on a 24h clock containing all wake times — a plain
  // max-min on minute-of-day breaks near midnight (23:50 vs 00:10 would
  // read as ~24h apart instead of 20 minutes). Sort, find the largest gap
  // between consecutive points (wrapping last→first), and the answer is
  // the full circle minus that gap.
  int? _wakeTimeVariabilityMinutes() {
    if (_recentSleepLogs.length < 2) return null;
    final minutesOfDay = _recentSleepLogs
        .map((log) => log.wakeTime.hour * 60 + log.wakeTime.minute)
        .toList()
      ..sort();

    const dayMinutes = 24 * 60;
    var largestGap = 0;
    for (var i = 0; i < minutesOfDay.length; i++) {
      final next =
          i + 1 < minutesOfDay.length ? minutesOfDay[i + 1] : minutesOfDay[0] + dayMinutes;
      final gap = next - minutesOfDay[i];
      if (gap > largestGap) largestGap = gap;
    }
    return dayMinutes - largestGap;
  }

  Future<void> _saveSleep(DateTime bedtime, DateTime wakeTime) async {
    final previous = _sleepLog;
    setState(() => _sleepLog = SleepLog(bedtime: bedtime, wakeTime: wakeTime));

    try {
      await _sleepService.saveLastNight(bedtime: bedtime, wakeTime: wakeTime);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sleepLog = previous);
      _showError(AppStrings.of(context).impossibileSalvareRiprova);
    }
  }

  Future<void> _loadFasting() async {
    try {
      final log = await _fastingService.loadToday();
      if (mounted) setState(() => _fastingLog = log);
    } catch (_) {
      // Row falls back to defaults if this fails.
    }
  }

  Future<void> _loadSound() async {
    try {
      final url = await _soundLinkService.loadToday();
      if (mounted) setState(() => _soundUrl = url);
    } catch (_) {
      // Row falls back to defaults if this fails.
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
      _showError(AppStrings.of(context).impossibileSalvareRiprova);
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
    } on PhotoValidationException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError(AppStrings.of(context).impossibileSalvareFotoRiprova);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPlantDiversity() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlantDiversityScreen()),
    );
    _loadPlants();
  }

  Future<void> _openStepDetail(RoutineStep step) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineStepDetailScreen(
          step: step,
          initiallyDone: _completedStepIds.contains(step.id),
        ),
      ),
    );
    _loadProgress();
  }

  Future<void> _importSleepFromHealth() async {
    final strings = AppStrings.of(context);
    final healthService = HealthService();
    final authorized = await healthService.requestAuthorization();
    if (!authorized) {
      if (!mounted) return;
      _showError(strings.permessoSaluteNegato);
      return;
    }

    final log = await healthService.fetchLastNightSleep();
    if (log == null) {
      if (!mounted) return;
      _showError(strings.nessunDatoSonnoInSalute);
      return;
    }

    if (mounted && log.source != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importato da: ${log.source}')),
      );
    }
    _saveSleep(log.bedtime, log.wakeTime);
  }

  Future<void> _openSleepScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SleepScreen()),
    );
    _loadSleep();
    _loadSleepRegularity();
  }

  Future<void> _openCycleScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CycleScreen()),
    );
    _loadCycleIfRelevant();
  }

  Future<void> _showSoundLinkDialog() async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: _soundUrl ?? '');
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.linkPerOggi),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: strings.linkSpotifyEcc),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.annulla),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(strings.salva),
          ),
        ],
      ),
    );

    if (url != null) _saveSound(url);
  }

  Future<void> _playSound() async {
    final url = _soundUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      _showError(AppStrings.of(context).impossibileAprireLink);
    }
  }

  String _greeting() {
    final base = AppStrings.of(context).greeting(DateTime.now().hour);
    if (_nickname == null || _nickname!.trim().isEmpty) return base;
    return '$base, ${_nickname!.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    final allSteps = _orderedRitualSteps();
    final ritualSteps = _fitToTimeBudget(allSteps);
    final strings = AppStrings.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          PageHeader(eyebrow: strings.todayEyebrow, title: _greeting()),
          const SizedBox(height: 24),
          _sectionTitle(strings.ritual),
          if (_timeBudgetMinutes != null && ritualSteps.length < allSteps.length) ...[
            const SizedBox(height: 6),
            Text(
              'In base ai tuoi $_timeBudgetMinutes min disponibili',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          if (_routineLoading)
            const Center(child: CircularProgressIndicator())
          else
            RitualOrbit(
              steps: ritualSteps,
              completedIds: _completedStepIds,
              onToggle: (step) => _toggleStep(step, !_completedStepIds.contains(step.id)),
              onOpenDetail: _openStepDetail,
            ),
          const SizedBox(height: 16),
          _buildStatGrid(),
          const SizedBox(height: 24),
          if (_userSex == UserSex.female) ...[
            _sectionTitle(strings.cicloMestruale),
            const SizedBox(height: 16),
            _buildCycleCard(),
            const SizedBox(height: 32),
          ],
          _sectionTitle(strings.prodottiSkincare),
          const SizedBox(height: 16),
          _buildSkincareCard(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelMedium);
  }

  String _sleepNote() {
    final strings = AppStrings.of(context);
    final variability = _wakeTimeVariabilityMinutes();
    if (variability == null) return strings.obiettivo9h;
    return strings.svegliaVariabileDi(
      _formatDuration(Duration(minutes: variability)),
      _recentSleepLogs.length,
    );
  }

  Widget _buildStatGrid() {
    final strings = AppStrings.of(context);
    final sleepTile = _statTile(
      icon: Icons.bedtime_outlined,
      label: strings.sonno,
      value: _sleepLog == null ? '—' : _formatDuration(_sleepLog!.duration),
      note: _sleepNote(),
      onTap: _openSleepScreen,
      secondaryIcon: Icons.favorite_outline,
      onSecondaryTap: _importSleepFromHealth,
    );
    final plantsTile = _statTile(
      icon: Icons.eco_outlined,
      label: strings.diversitaVegetale,
      value: '${_plants.length} / 30',
      note: _plants.isEmpty ? strings.daLunedi : _plants.join(', '),
      onTap: _openPlantDiversity,
    );
    final soundTile = _statTile(
      icon: Icons.music_note_outlined,
      label: strings.suonoDiOggi,
      value: _soundUrl == null ? strings.nessunLink : strings.linkSalvato,
      note: _soundUrl ?? strings.aggiungiUnLinkPerOggi,
      onTap: _showSoundLinkDialog,
      secondaryIcon: _soundUrl == null ? null : Icons.play_arrow,
      onSecondaryTap: _soundUrl == null ? null : _playSound,
    );
    final fastingTile = _fastingEnabled
        ? _statTile(
            icon: Icons.timer_outlined,
            label: strings.digiuno,
            value: _fastingLog.lastMealTime == null
                ? '—'
                : _formatDuration(DateTime.now().difference(_fastingLog.lastMealTime!)),
            note: strings.obiettivo16h,
            onTap: _openFastingDetail,
          )
        : null;

    final tiles = [plantsTile, sleepTile, ?fastingTile, soundTile];
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      rows.add(tiles[i]);
      if (i < tiles.length - 1) rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required String note,
    required VoidCallback onTap,
    IconData? secondaryIcon,
    VoidCallback? onSecondaryTap,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      blur: 0,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.outline),
                  if (secondaryIcon != null)
                    GestureDetector(
                      onTap: onSecondaryTap,
                      child: Icon(secondaryIcon, size: 18, color: theme.colorScheme.primary),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(value, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label.toUpperCase(), style: theme.textTheme.labelMedium),
              const SizedBox(height: 3),
              Text(note, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFastingDetail() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FastingDetailScreen()),
    );
    _loadFasting();
  }

  Widget _buildCycleCard() {
    final strings = AppStrings.of(context);
    return AppCard(
      blur: 0,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: _openCycleScreen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _cycleLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cycleInfo == null
                                ? strings.cicloNonTracciato
                                : strings.giornoFase(
                                    _cycleInfo!.cycleDay, _phaseLabel(_cycleInfo!.phase)),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_cycleInfo != null)
                            Text(
                              strings.prossimoCiclo(
                                _formatDate(_cycleInfo!.predictedNextStart),
                                _cycleInfo!.avgCycleLength,
                              ),
                              style: TextStyle(color: Theme.of(context).colorScheme.outline),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                  ],
                ),
        ),
      ),
    );
  }

  String _phaseLabel(CyclePhase phase) {
    final strings = AppStrings.of(context);
    switch (phase) {
      case CyclePhase.menstrual:
        return strings.faseMestruale;
      case CyclePhase.follicular:
        return strings.faseFollicolare;
      case CyclePhase.ovulation:
        return strings.faseOvulazione;
      case CyclePhase.luteal:
        return strings.faseLuteale;
    }
  }

  Widget _buildSkincareCard() {
    final strings = AppStrings.of(context);
    return AppCard(blur: 0, padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _skincareLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  Expanded(child: _skincareSlot(SkincarePeriod.mattino, strings.mattino)),
                  const SizedBox(width: 16),
                  Expanded(child: _skincareSlot(SkincarePeriod.sera, strings.sera)),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
