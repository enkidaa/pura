import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/cycle_info.dart';
import '../services/cycle_service.dart';
import '../services/health_service.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  final _cycleService = CycleService();
  final _healthService = HealthService();

  bool _loading = true;
  CycleInfo? _info;
  List<DateTime> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _cycleService.loadCycleInfo(),
        _cycleService.loadPeriodStartsHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _info = results[0] as CycleInfo?;
        _history = results[1] as List<DateTime>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logToday() async {
    try {
      await _cycleService.logPeriodStart(DateTime.now());
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showError(AppStrings.of(context).impossibileSalvareRiprova);
    }
  }

  Future<void> _syncFromHealth() async {
    final authorized = await _healthService.requestMenstrualAuthorization();
    if (!authorized) {
      if (!mounted) return;
      _showError(AppStrings.of(context).permessoSaluteNegato);
      return;
    }
    final starts = await _healthService.fetchMenstrualPeriodStarts();
    if (starts.isEmpty) {
      if (!mounted) return;
      _showError('Nessun dato ciclo trovato in Salute.');
      return;
    }
    try {
      await _cycleService.importPeriodStarts(starts);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showError(AppStrings.of(context).impossibileSalvareRiprova);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final info = _info;

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
                  const PageHeader(eyebrow: 'Salute', title: 'Ciclo'),
                  const SizedBox(height: 20),
                  AppCard(
                    blur: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info == null
                              ? strings.cicloNonTracciato
                              : strings.giornoFase(info.cycleDay, _phaseLabel(info.phase)),
                          style: theme.textTheme.titleLarge,
                        ),
                        if (info != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            strings.prossimoCiclo(_formatDate(info.predictedNextStart), info.avgCycleLength),
                            style: TextStyle(color: theme.colorScheme.outline),
                          ),
                          const SizedBox(height: 16),
                          _CycleTimeline(info: info),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _logToday,
                                child: Text(strings.segnaInizioCicloOggi),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _syncFromHealth,
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
                  Text('I TUOI CICLI', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    Text(
                      'Nessun ciclo registrato ancora.',
                      style: theme.textTheme.bodySmall,
                    )
                  else ...[
                    Text(
                      'Le stime di durata mestruale e finestra fertile sono indicative, non '
                      'misurate — quest\'app registra solo la data di inizio. Non usarle come '
                      'metodo contraccettivo.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 16),
                    Builder(builder: (context) {
                      final entries = CycleHistoryEntry.fromStartsDescending(_history);
                      return AppCard(
                        blur: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < entries.length; i++) ...[
                              _CycleHistoryRow(entry: entries[i], formatDate: _formatDate),
                              if (i < entries.length - 1)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Divider(height: 1),
                                ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
      ),
    );
  }
}

/// A single cycle's row in the history list: title + estimated period
/// length + a day-by-day indicator strip.
class _CycleHistoryRow extends StatelessWidget {
  const _CycleHistoryRow({required this.entry, required this.formatDate});

  final CycleHistoryEntry entry;
  final String Function(DateTime) formatDate;

  String _formatShort(DateTime date) {
    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = entry.isCurrent
        ? 'Ciclo corrente: iniziato il ${formatDate(entry.startDate)} (${entry.totalLengthDays} giorni)'
        : '${entry.totalLengthDays} giorni: ${_formatShort(entry.startDate)} - '
            '${_formatShort(entry.endDateExclusive.subtract(const Duration(days: 1)))}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          'Mestruazione stimata di ${entry.estimatedPeriodLengthDays} giorni',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        _CycleDayIndicatorRow(entry: entry),
      ],
    );
  }
}

/// One segment per day of the cycle — colored for the estimated period and
/// estimated fertile window, faint for every other day. Uses the theme's
/// own primary/secondary accents, never a literal red/blue.
class _CycleDayIndicatorRow extends StatelessWidget {
  const _CycleDayIndicatorRow({required this.entry});

  final CycleHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Clamped defensively — a data-entry mistake (e.g. two start dates
    // logged a year apart) shouldn't render hundreds of slivers.
    final totalDays = entry.totalLengthDays.clamp(1, 60);
    final fertileEnd = entry.estimatedFertileWindowStartDay + entry.estimatedFertileWindowLengthDays;

    return Row(
      children: List.generate(totalDays, (i) {
        final day = i + 1;
        final Color color;
        if (day <= entry.estimatedPeriodLengthDays) {
          color = scheme.primary;
        } else if (day >= entry.estimatedFertileWindowStartDay && day < fertileEnd) {
          color = scheme.secondary;
        } else {
          color = scheme.outlineVariant;
        }
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              height: 8,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        );
      }),
    );
  }
}

/// Timeline a segmenti di fase (mestruale/follicolare/ovulazione/luteale)
/// nello stile della Health app — proporzioni approssimative sul ciclo
/// medio, con un marcatore sul giorno di oggi. Non è una previsione
/// medica, solo una lettura visiva della stima già calcolata in CycleInfo.
class _CycleTimeline extends StatelessWidget {
  const _CycleTimeline({required this.info});

  final CycleInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = info.avgCycleLength;
    final ovulationDay = total - 14;

    final segments = <(int, Color)>[
      (5, theme.colorScheme.error.withValues(alpha: 0.55)),
      ((ovulationDay - 1 - 5).clamp(1, total), theme.colorScheme.secondary.withValues(alpha: 0.5)),
      (3, theme.colorScheme.primary.withValues(alpha: 0.6)),
      ((total - (ovulationDay + 2)).clamp(1, total), theme.colorScheme.tertiary.withValues(alpha: 0.45)),
    ];
    final todayFraction = (info.cycleDay / total).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Row(
                  children: segments
                      .map((seg) => Expanded(
                            flex: seg.$1,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(color: seg.$2),
                            ),
                          ))
                      .toList(),
                ),
                Positioned(
                  left: (w * todayFraction - 1).clamp(0.0, w - 2),
                  child: Container(width: 2, height: 14, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Ciclo medio: $total giorni', style: theme.textTheme.bodySmall),
          ],
        );
      },
    );
  }
}
