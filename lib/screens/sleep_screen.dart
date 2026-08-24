import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/sleep_log.dart';
import '../services/health_service.dart';
import '../services/sleep_service.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

const _weekdayShort = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final _sleepService = SleepService();
  final _healthService = HealthService();

  bool _loading = true;
  SleepLog? _lastNight;
  List<SleepLog> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _sleepService.loadLastNight(),
        _sleepService.loadRecentSleepLogs(),
      ]);
      if (!mounted) return;
      setState(() {
        _lastNight = results[0] as SleepLog?;
        _recentLogs = results[1] as List<SleepLog>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _wakeTimeVariabilityMinutes() {
    if (_recentLogs.length < 2) return null;
    final minutesOfDay = _recentLogs
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

  Duration? get _weeklyAverage {
    if (_recentLogs.isEmpty) return null;
    final totalMinutes = _recentLogs.fold<int>(0, (sum, l) => sum + l.duration.inMinutes);
    return Duration(minutes: totalMinutes ~/ _recentLogs.length);
  }

  String _formatDuration(Duration d) => '${d.inHours}h ${d.inMinutes.remainder(60)}m';

  Future<void> _logManually() async {
    final strings = AppStrings.of(context);
    var bedtime = _lastNight != null
        ? TimeOfDay.fromDateTime(_lastNight!.bedtime)
        : const TimeOfDay(hour: 23, minute: 0);
    var wakeTime = _lastNight != null
        ? TimeOfDay.fromDateTime(_lastNight!.wakeTime)
        : const TimeOfDay(hour: 7, minute: 0);

    final pickedBedtime = await showTimePicker(
      context: context,
      initialTime: bedtime,
      helpText: strings.aCheOraSeiAndatoALetto,
    );
    if (pickedBedtime == null) return;
    bedtime = pickedBedtime;

    if (!mounted) return;
    final pickedWakeTime = await showTimePicker(
      context: context,
      initialTime: wakeTime,
      helpText: strings.aCheOraTiSeiSvegliato,
    );
    if (pickedWakeTime == null) return;
    wakeTime = pickedWakeTime;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final bedtimeDate =
        DateTime(yesterday.year, yesterday.month, yesterday.day, bedtime.hour, bedtime.minute);
    final wakeTimeDate =
        DateTime(today.year, today.month, today.day, wakeTime.hour, wakeTime.minute);

    await _save(bedtimeDate, wakeTimeDate);
  }

  Future<void> _save(DateTime bedtime, DateTime wakeTime) async {
    final previous = _lastNight;
    setState(() => _lastNight = SleepLog(bedtime: bedtime, wakeTime: wakeTime));
    try {
      await _sleepService.saveLastNight(bedtime: bedtime, wakeTime: wakeTime);
      _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _lastNight = previous);
      _showError(AppStrings.of(context).impossibileSalvareRiprova);
    }
  }

  Future<void> _importFromHealth() async {
    final strings = AppStrings.of(context);
    final authorized = await _healthService.requestAuthorization();
    if (!authorized) {
      if (!mounted) return;
      _showError(strings.permessoSaluteNegato);
      return;
    }
    final log = await _healthService.fetchLastNightSleep();
    if (log == null) {
      if (!mounted) return;
      _showError(strings.nessunDatoSonnoInSalute);
      return;
    }
    await _save(log.bedtime, log.wakeTime);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variability = _wakeTimeVariabilityMinutes();
    final average = _weeklyAverage;

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
                  const PageHeader(eyebrow: 'Salute', title: 'Sonno'),
                  const SizedBox(height: 20),
                  AppCard(
                    blur: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lastNight == null ? '—' : _formatDuration(_lastNight!.duration),
                          style: theme.textTheme.displaySmall,
                        ),
                        Text('Notte scorsa', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _logManually,
                                child: const Text('Registra manualmente'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _importFromHealth,
                                icon: const Icon(Icons.favorite_outline, size: 16),
                                label: const Text('Da Salute'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('ULTIME 7 NOTTI', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 12),
                  AppCard(blur: 0, child: _SleepTimeline(logs: _recentLogs)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          blur: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                average == null ? '—' : _formatDuration(average),
                                style: theme.textTheme.titleLarge,
                              ),
                              Text('Media 7 notti', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          blur: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variability == null ? '—' : '${variability}m',
                                style: theme.textTheme.titleLarge,
                              ),
                              Text('Variabilità sveglia', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bar-range timeline nello stile Apple Salute: ogni riga è una notte,
/// la barra rappresenta la finestra reale bedtime→wake su un asse fisso
/// 18:00 → 12:00 del giorno dopo (18 ore), non solo la durata.
class _SleepTimeline extends StatelessWidget {
  const _SleepTimeline({required this.logs});

  final List<SleepLog> logs;

  static const _spanHours = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (logs.isEmpty) {
      return Text('Nessun dato ancora — registra la notte scorsa per iniziare.',
          style: theme.textTheme.bodySmall);
    }

    // Most recent last, so the chart reads top (oldest) to bottom (newest)...
    // actually keep most-recent-first order as loaded, top row = last night.
    return Column(
      children: logs.map((log) {
        final reference =
            DateTime(log.bedtime.year, log.bedtime.month, log.bedtime.day, 18, 0);
        final startFraction =
            (log.bedtime.difference(reference).inMinutes / (_spanHours * 60)).clamp(0.0, 1.0);
        final endFraction =
            (log.wakeTime.difference(reference).inMinutes / (_spanHours * 60)).clamp(0.0, 1.0);
        final weekday = _weekdayShort[log.bedtime.weekday - 1];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 20, child: Text(weekday, style: theme.textTheme.bodySmall)),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Positioned(
                          left: w * startFraction,
                          width: (w * (endFraction - startFraction)).clamp(4.0, w),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  '${log.duration.inHours}h${log.duration.inMinutes.remainder(60)}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
