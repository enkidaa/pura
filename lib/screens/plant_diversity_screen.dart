import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/plant_food.dart';
import '../services/plant_diversity_service.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

const _weeklyGoal = 30;
const _collapsedCount = 8;

class PlantDiversityScreen extends StatefulWidget {
  const PlantDiversityScreen({super.key});

  @override
  State<PlantDiversityScreen> createState() => _PlantDiversityScreenState();
}

class _PlantDiversityScreenState extends State<PlantDiversityScreen> {
  final _service = PlantDiversityService();
  final _searchController = TextEditingController();

  List<PlantLog> _logs = [];
  bool _loading = true;
  PlantCategory _selectedCategory = PlantCategory.frutta;
  bool _categoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final logs = await _service.loadLogsThisWeek();
      if (mounted) setState(() { _logs = logs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Set<String> get _loggedNames => _logs.map((l) => l.name.toLowerCase()).toSet();

  Future<void> _addPlant(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // Only plants from the curated vocabulary count — keeps the list
    // meaningful for microbiome diversity instead of any typed word.
    String? canonical;
    for (final food in plantVocabulary) {
      if (food.name.toLowerCase() == trimmed.toLowerCase()) {
        canonical = food.name;
        break;
      }
    }
    if (canonical == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"$trimmed" ${AppStrings.of(context).pianteNonInElenco}'),
      ));
      return;
    }
    final resolvedName = canonical;
    if (_loggedNames.contains(resolvedName.toLowerCase())) return;

    final previous = _logs;
    setState(() => _logs = [..._logs, PlantLog(name: resolvedName, loggedOn: DateTime.now())]);
    _searchController.clear();

    try {
      await _service.logPlant(resolvedName);
    } catch (_) {
      if (!mounted) return;
      setState(() => _logs = previous);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.of(context).impossibileSalvareRiprova)));
    }
  }

  Future<void> _removePlant(String name) async {
    final previous = _logs;
    setState(() => _logs = _logs.where((l) => l.name.toLowerCase() != name.toLowerCase()).toList());

    try {
      await _service.removePlantThisWeek(name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _logs = previous);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.of(context).impossibileRimuovereRiprova)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final scheme = theme.colorScheme;
    final count = _loggedNames.length;
    final progress = (count / _weeklyGoal).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  PageHeader(
                    eyebrow: strings.questaSettimana,
                    title: strings.punti30Piante,
                    subtitle: strings.puntiPianteSottotitolo,
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    blur: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.eco_outlined, size: 16, color: scheme.outline),
                                const SizedBox(width: 8),
                                Text(strings.diversitaSettimanale, style: theme.textTheme.labelMedium),
                              ],
                            ),
                            Text(strings.obiettivoN(_weeklyGoal), style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.displayMedium,
                            children: [
                              TextSpan(text: '$count'),
                              TextSpan(
                                text: strings.suGoalPiante(_weeklyGoal),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation(scheme.primary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          count >= _weeklyGoal
                              ? strings.obiettivoRaggiuntoSettimana
                              : strings.ancoraNPianteObiettivo(_weeklyGoal - count),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AppCard(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.secondary.withValues(alpha: 0.28),
                        scheme.primary.withValues(alpha: 0.14),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: scheme.outline),
                            const SizedBox(width: 8),
                            Text(strings.perche30, style: theme.textTheme.labelMedium),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.spiegazionePerche30,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  AppCard(
                    blur: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.aggiungiRapidamente, style: theme.textTheme.labelMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(hintText: strings.cercaOScriviUnaPianta),
                                onSubmitted: _addPlant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addPlant(_searchController.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: PlantCategory.values.map((category) {
                              final selected = category == _selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(plantCategoryLabel(category, strings)),
                                  selected: selected,
                                  onSelected: (_) => setState(() {
                                    _selectedCategory = category;
                                    _categoryExpanded = false;
                                  }),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Builder(builder: (context) {
                          final categoryFoods = plantVocabulary
                              .where((f) => f.category == _selectedCategory)
                              .toList();
                          final visible = _categoryExpanded
                              ? categoryFoods
                              : categoryFoods.take(_collapsedCount).toList();
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...visible.map((food) {
                                final logged = _loggedNames.contains(food.name.toLowerCase());
                                return OutlinedButton(
                                  onPressed:
                                      logged ? () => _removePlant(food.name) : () => _addPlant(food.name),
                                  child: Text(
                                    logged ? food.name : '+ ${food.name}',
                                    style: logged
                                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                                        : null,
                                  ),
                                );
                              }),
                              if (categoryFoods.length > _collapsedCount)
                                TextButton(
                                  onPressed: () => setState(() => _categoryExpanded = !_categoryExpanded),
                                  child: Text(
                                    _categoryExpanded
                                        ? strings.mostraMeno
                                        : strings.mostraTuttiN(categoryFoods.length),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  AppCard(
                    blur: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.consumateQuestaSettimana(count), style: theme.textTheme.labelMedium),
                        const SizedBox(height: 12),
                        if (_loggedNames.isEmpty)
                          Text(
                            strings.nessunaPiantaAnnotataAncora,
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _loggedNames
                                .map((name) => Chip(
                                      label: Text(name),
                                      onDeleted: () => _removePlant(name),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  AppCard(
                    blur: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.perGruppo, style: theme.textTheme.labelMedium),
                        const SizedBox(height: 12),
                        ...PlantCategory.values.map((category) {
                          final n = _loggedNames
                              .where((name) => categoryForPlant(name) == category)
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(plantCategoryLabel(category, strings), style: theme.textTheme.bodyMedium),
                                    Text('$n', style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: n == 0 ? 0 : (n / 5).clamp(0.0, 1.0),
                                    minHeight: 4,
                                    backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
