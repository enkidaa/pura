import 'package:flutter/material.dart';

import '../models/mix_recipe.dart';
import '../services/lab_service.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final _labService = LabService();

  Set<String> _ingredients = {};
  bool _ingredientsLoading = true;

  List<MixDiaryEntry> _diary = [];
  bool _diaryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
    _loadDiary();
  }

  Future<void> _loadIngredients() async {
    try {
      final ingredients = await _labService.loadIngredients();
      setState(() {
        _ingredients = ingredients;
        _ingredientsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _ingredientsLoading = false);
    }
  }

  Future<void> _loadDiary() async {
    try {
      final diary = await _labService.loadRecentDiary();
      setState(() {
        _diary = diary;
        _diaryLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _diaryLoading = false);
    }
  }

  Future<void> _addIngredient(String name) async {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty || _ingredients.contains(trimmed)) return;

    setState(() => _ingredients = {..._ingredients, trimmed});

    try {
      await _labService.addIngredient(trimmed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ingredients = _ingredients.where((i) => i != trimmed).toSet());
      _showError('Impossibile salvare, riprova');
    }
  }

  Future<void> _removeIngredient(String name) async {
    setState(() => _ingredients = _ingredients.where((i) => i != name).toSet());

    try {
      await _labService.removeIngredient(name);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ingredients = {..._ingredients, name});
      _showError('Impossibile rimuovere, riprova');
    }
  }

  Future<void> _logMixMade(String mixName) async {
    try {
      await _labService.logMixMade(mixName);
      await _loadDiary();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Aggiunto al diario: $mixName')));
    } catch (_) {
      if (!mounted) return;
      _showError('Impossibile salvare, riprova');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddIngredientDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi un ingrediente'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Es. curcuma'),
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

    if (name != null) _addIngredient(name);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ingredienti', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildIngredientsCard(),
          const SizedBox(height: 32),
          Text('Mix', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...allMixRecipes.map(_buildMixCard),
          const SizedBox(height: 32),
          Text('Diario', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildDiaryCard(),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _ingredientsLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('I tuoi ingredienti'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _showAddIngredientDialog,
                      ),
                    ],
                  ),
                  if (_ingredients.isEmpty)
                    const Text(
                      'Aggiungi i tuoi ingredienti per vedere quali mix puoi preparare subito.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ingredients
                          .map((i) => Chip(
                                label: Text(i),
                                onDeleted: () => _removeIngredient(i),
                              ))
                          .toList(),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildMixCard(MixRecipe mix) {
    final missing = mix.ingredients.where((i) => !_ingredients.contains(i)).toList();
    final ready = missing.isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(mix.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (ready)
                  const Chip(
                    label: Text('Pronto'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(mix.description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: mix.ingredients
                  .map((i) => Chip(
                        label: Text(i),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: _ingredients.contains(i)
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : null,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _logMixMade(mix.name),
              child: const Text('Ho preparato questo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _diaryLoading
            ? const Center(child: CircularProgressIndicator())
            : _diary.isEmpty
                ? const Text('Nessuna voce nel diario ancora.', style: TextStyle(color: Colors.grey))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _diary
                        .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${entry.mixName} — ${_formatDate(entry.madeAt)}',
                              ),
                            ))
                        .toList(),
                  ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
