import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/practice.dart';
import '../models/practice_catalog.dart';
import '../models/schedule_spec.dart';
import '../services/practice_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/evidence_badge.dart';
import '../widgets/page_header.dart';
import 'fasting_detail_screen.dart';
import 'practice_detail_screen.dart';

class PracticesScreen extends StatefulWidget {
  const PracticesScreen({super.key});

  @override
  State<PracticesScreen> createState() => _PracticesScreenState();
}

class _PracticesScreenState extends State<PracticesScreen> {
  final _service = PracticeService();
  final _settingsService = SettingsService();
  final _searchController = TextEditingController();

  Set<String> _routineIds = {};
  Map<String, ScheduleSpec> _schedules = {};
  WellnessApproach _approach = WellnessApproach.balanced;
  bool _loading = true;
  PracticeCategory? _selectedCategory;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.loadRoutinePracticeIds(),
        _settingsService.loadSettings(),
      ]);
      if (!mounted) return;
      final routineIds = results[0] as Set<String>;
      final schedules = await _service.loadSchedulesFor(routineIds);
      if (!mounted) return;
      setState(() {
        _routineIds = routineIds;
        _schedules = schedules;
        _approach = (results[1] as AppSettings).approach;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Practice> get _filtered {
    final matches = practiceCatalog.where((p) {
      if (_selectedCategory != null && p.category != _selectedCategory) return false;
      if (_query.isEmpty) return true;
      return p.name.toLowerCase().contains(_query) ||
          p.description.toLowerCase().contains(_query) ||
          p.tags.any((t) => t.toLowerCase().contains(_query));
    }).toList();
    // Practices aligned with the user's saved approach surface first,
    // preserving catalog order within each group — never hidden, just
    // reordered (brief sez.1: l'approccio pesa sulle raccomandazioni).
    // Practices with a known risk/contraindication are never promoted for
    // approach-consistency alone — safety always outranks preference, so
    // they stay in natural catalog order regardless of match.
    final aligned = matches.where((p) => p.matchesApproach(_approach) && p.risks == null).toList();
    final rest = matches.where((p) => !p.matchesApproach(_approach) || p.risks != null).toList();
    return [...aligned, ...rest];
  }

  Future<void> _openPractice(Practice practice) async {
    if (practice.linksToFastingDetail) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FastingDetailScreen()),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PracticeDetailScreen(practice: practice)),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final results = _filtered;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    eyebrow: strings.laLibreria,
                    title: strings.pratiche,
                    subtitle: strings.pratichesottotitolo,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: strings.cercaUnaPratica,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(strings.tutte),
                            selected: _selectedCategory == null,
                            onSelected: (_) => setState(() => _selectedCategory = null),
                          ),
                        ),
                        ...PracticeCategory.values.map((category) {
                          final selected = category == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(practiceCategoryLabel(category, strings)),
                              selected: selected,
                              onSelected: (_) => setState(
                                () => _selectedCategory = selected ? null : category,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_loading) const Center(child: CircularProgressIndicator()),
                  if (!_loading && results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        strings.nessunaPraticaTrovata,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!_loading && results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final practice = results[index];
                  final inRoutine = _routineIds.contains(practice.id);
                  final aligned = practice.matchesApproach(_approach);
                  final dueToday = inRoutine &&
                      (_schedules[practice.id] ?? const ScheduleSpec()).isDueOn(DateTime.now());
                  return AppCard(
                    padding: EdgeInsets.zero,
                    blur: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => _openPractice(practice),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(practice.name, style: theme.textTheme.titleMedium),
                                ),
                                if (inRoutine)
                                  Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${practiceCategoryLabel(practice.category, strings)} · ${practice.frequency}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                EvidenceBadge(level: practice.evidenceLevel),
                                if (aligned)
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    avatar: Icon(Icons.tune, size: 14, color: theme.colorScheme.primary),
                                    label: Text(strings.allineatoAlTuoApproccio),
                                    labelStyle: theme.textTheme.labelSmall,
                                  ),
                                if (dueToday)
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(strings.oggi),
                                    labelStyle: theme.textTheme.labelSmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
