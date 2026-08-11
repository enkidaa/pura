import 'package:flutter/material.dart';

import '../models/supplement.dart';
import '../services/supplement_service.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final _supplementService = SupplementService();

  List<Supplement> _supplements = [];
  Set<String> _takenToday = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _supplementService.loadSupplements(),
        _supplementService.loadTodayIntake(),
      ]);
      setState(() {
        _supplements = results[0] as List<Supplement>;
        _takenToday = results[1] as Set<String>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleTaken(Supplement supplement, bool taken) async {
    setState(() {
      if (taken) {
        _takenToday.add(supplement.id);
      } else {
        _takenToday.remove(supplement.id);
      }
    });

    try {
      await _supplementService.setIntakeToday(supplement.id, taken);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (taken) {
          _takenToday.remove(supplement.id);
        } else {
          _takenToday.add(supplement.id);
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile salvare, riprova')));
    }
  }

  Future<void> _removeSupplement(Supplement supplement) async {
    final previous = _supplements;
    setState(() => _supplements = _supplements.where((s) => s.id != supplement.id).toList());

    try {
      await _supplementService.removeSupplement(supplement.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _supplements = previous);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile eliminare, riprova')));
    }
  }

  Future<void> _showAddSupplementDialog() async {
    final controller = TextEditingController();
    var category = SupplementCategory.natural;

    final result = await showDialog<(String, SupplementCategory)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aggiungi integratore'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Es. vitamina D, NAD+, zenzero...'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<SupplementCategory>(
                segments: const [
                  ButtonSegment(value: SupplementCategory.natural, label: Text('Naturale')),
                  ButtonSegment(value: SupplementCategory.scientific, label: Text('Scientifico')),
                ],
                selected: {category},
                onSelectionChanged: (selection) =>
                    setDialogState(() => category = selection.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((controller.text, category)),
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final (name, chosenCategory) = result;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      await _supplementService.addSupplement(trimmed, chosenCategory);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossibile aggiungere, riprova')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          else if (_supplements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nessun integratore ancora. Aggiungine uno con il pulsante sotto.',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            )
          else
            ..._supplements.map((supplement) {
              final taken = _takenToday.contains(supplement.id);
              return AppCard(padding: EdgeInsets.zero, 
                child: CheckboxListTile(
                  value: taken,
                  onChanged: (value) => _toggleTaken(supplement, value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(supplement.name),
                  subtitle: Text(
                    supplement.category == SupplementCategory.natural
                        ? 'Naturale'
                        : 'Scientifico',
                  ),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeSupplement(supplement),
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showAddSupplementDialog,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi integratore'),
          ),
        ],
      ),
    );
  }
}
