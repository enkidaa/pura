import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/schedule_spec.dart';
import '../models/supplement_catalog.dart';
import '../services/settings_service.dart';
import '../services/supplement_service.dart';
import '../widgets/app_card.dart';
import '../widgets/evidence_badge.dart';
import '../widgets/page_header.dart';
import 'supplement_detail_screen.dart';

String _approachLabel(WellnessApproach approach) {
  switch (approach) {
    case WellnessApproach.natural:
      return 'naturale';
    case WellnessApproach.balanced:
      return 'bilanciato';
    case WellnessApproach.scientific:
      return 'scientifico';
  }
}

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final _supplementService = SupplementService();
  final _settingsService = SettingsService();
  final _searchController = TextEditingController();

  Set<String> _takenToday = {};
  Set<String> _routineIds = {};
  Map<String, ScheduleSpec> _schedules = {};
  WellnessApproach _approach = WellnessApproach.balanced;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _supplementService.loadTodayIntake(),
        _supplementService.loadRoutineIds(),
        _settingsService.loadSettings(),
      ]);
      if (!mounted) return;
      final routineIds = results[1] as Set<String>;
      final schedules = await _supplementService.loadSchedulesFor(routineIds);
      if (!mounted) return;
      setState(() {
        _takenToday = results[0] as Set<String>;
        _routineIds = routineIds;
        _schedules = schedules;
        _approach = (results[2] as AppSettings).approach;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openItem(SupplementCatalogItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SupplementDetailScreen(item: item)),
    );
    _load();
  }

  List<SupplementCatalogItem> _recommendations() {
    final notInRoutine = supplementCatalog.where((i) => !_routineIds.contains(i.id)).toList();
    notInRoutine.sort((a, b) {
      final aMatch = a.approachAffinity.contains(_approach) ? 0 : 1;
      final bMatch = b.approachAffinity.contains(_approach) ? 0 : 1;
      return aMatch.compareTo(bMatch);
    });
    return notInRoutine.take(3).toList();
  }

  String _reasonFor(SupplementCatalogItem item) {
    if (item.approachAffinity.contains(_approach)) {
      return 'Perché: si allinea al tuo approccio ${_approachLabel(_approach)} — ${item.benefits}';
    }
    return 'Perché: ${item.benefits}';
  }

  List<SupplementCatalogItem> _filteredCatalog() {
    if (_query.isEmpty) return supplementCatalog;
    return supplementCatalog
        .where((i) =>
            i.name.toLowerCase().contains(_query) || i.benefits.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yours = supplementCatalog.where((i) => _routineIds.contains(i.id)).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const PageHeader(
            eyebrow: 'Spazio di lavoro',
            title: 'Integratori',
            subtitle: 'Naturali e mirati/da ricerca, monitorati nel tempo — non un consiglio medico.',
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Text('I TUOI INTEGRATORI', style: theme.textTheme.labelMedium),
            const SizedBox(height: 10),
            if (yours.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Non hai ancora aggiunto integratori alla tua routine. Esplorali qui sotto.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else ...[
              ...yours.map((item) => _SupplementRow(
                    item: item,
                    takenToday: _takenToday.contains(item.id),
                    inRoutine: true,
                    dueToday: (_schedules[item.id] ?? const ScheduleSpec()).isDueOn(DateTime.now()),
                    onTap: () => _openItem(item),
                  )),
              const SizedBox(height: 20),
            ],
            Text('CONSIGLIATI PER TE', style: theme.textTheme.labelMedium),
            const SizedBox(height: 10),
            ..._recommendations().map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    blur: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => _openItem(item),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(_reasonFor(item), style: theme.textTheme.bodySmall),
                            const SizedBox(height: 8),
                            EvidenceBadge(level: item.evidenceLevel),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            Text('ESPLORA TUTTI', style: theme.textTheme.labelMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cerca un integratore...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            ..._filteredCatalog().map((item) => _SupplementRow(
                  item: item,
                  takenToday: _takenToday.contains(item.id),
                  inRoutine: _routineIds.contains(item.id),
                  dueToday: _routineIds.contains(item.id) &&
                      (_schedules[item.id] ?? const ScheduleSpec()).isDueOn(DateTime.now()),
                  onTap: () => _openItem(item),
                )),
          ],
        ],
      ),
    );
  }
}

class _SupplementRow extends StatelessWidget {
  const _SupplementRow({
    required this.item,
    required this.takenToday,
    required this.inRoutine,
    required this.onTap,
    this.dueToday = false,
  });

  final SupplementCatalogItem item;
  final bool takenToday;
  final bool inRoutine;
  final bool dueToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      blur: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${item.frequency} · ${item.durationMinutes} min',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        EvidenceBadge(level: item.evidenceLevel),
                        if (dueToday)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: const Text('Oggi'),
                            labelStyle: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (inRoutine)
                Icon(Icons.bookmark, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              if (takenToday)
                Icon(Icons.check_circle, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
