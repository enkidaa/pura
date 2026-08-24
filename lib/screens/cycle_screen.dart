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
                  Text('CRONOLOGIA', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    Text(
                      'Nessun ciclo registrato ancora.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    ..._history.map((date) => AppCard(
                          padding: EdgeInsets.zero,
                          blur: 0,
                          child: ListTile(title: Text(_formatDate(date))),
                        )),
                ],
              ),
      ),
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
