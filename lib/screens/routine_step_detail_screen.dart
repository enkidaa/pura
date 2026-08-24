import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/routine_step.dart';
import '../services/routine_progress_service.dart';
import '../widgets/app_card.dart';

class RoutineStepDetailScreen extends StatefulWidget {
  const RoutineStepDetailScreen({super.key, required this.step, required this.initiallyDone});

  final RoutineStep step;
  final bool initiallyDone;

  @override
  State<RoutineStepDetailScreen> createState() => _RoutineStepDetailScreenState();
}

class _RoutineStepDetailScreenState extends State<RoutineStepDetailScreen> {
  final _service = RoutineProgressService();
  final _noteController = TextEditingController();
  final _sourceController = TextEditingController();

  bool _loading = true;
  late bool _done;
  List<RoutineStepSource> _sources = [];

  @override
  void initState() {
    super.initState();
    _done = widget.initiallyDone;
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.loadNote(widget.step.id),
        _service.loadSources(widget.step.id),
      ]);
      if (!mounted) return;
      setState(() {
        _noteController.text = results[0] as String;
        _sources = results[1] as List<RoutineStepSource>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleDone(bool value) async {
    setState(() => _done = value);
    try {
      await _service.setStepCompleted(widget.step.id, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _done = !value);
    }
  }

  Future<void> _saveNote() async {
    try {
      await _service.saveNote(widget.step.id, _noteController.text.trim());
    } catch (_) {
      // Non-blocking — the field just keeps the unsaved text locally.
    }
  }

  Future<void> _addSource() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) return;
    _sourceController.clear();
    try {
      await _service.addSource(widget.step.id, text);
      final sources = await _service.loadSources(widget.step.id);
      if (mounted) setState(() => _sources = sources);
    } catch (_) {
      // Silent — user can retype and retry.
    }
  }

  Future<void> _removeSource(String id) async {
    final previous = _sources;
    setState(() => _sources = _sources.where((s) => s.id != id).toList());
    try {
      await _service.removeSource(id);
    } catch (_) {
      if (mounted) setState(() => _sources = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = widget.step;

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
                  Text('IL RITUALE', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Text(step.title, style: theme.textTheme.displaySmall),
                  const SizedBox(height: 10),
                  Chip(
                    label: Text('${step.durationMinutes} min'),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    blur: 0,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fatto oggi'),
                      value: _done,
                      onChanged: _toggleDone,
                    ),
                  ),
                  Text('INFO', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  Text(step.benefits, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  Text('FONTI SCIENTIFICHE', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  ...step.sources.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication),
                              child: Text(
                                s.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            if (s.note != null) ...[
                              const SizedBox(height: 4),
                              Text(s.note!, style: theme.textTheme.bodySmall),
                            ],
                          ],
                        ),
                      )),
                  if (step.sources.isNotEmpty) const SizedBox(height: 8),
                  Text('LE TUE FONTI', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  if (_sources.isEmpty)
                    Text(
                      'Nessuna fonte ancora. Aggiungine una qui sotto — è solo per te.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    ..._sources.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(s.text, style: theme.textTheme.bodyMedium)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _removeSource(s.id),
                              ),
                            ],
                          ),
                        )),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sourceController,
                          decoration: const InputDecoration(hintText: 'Aggiungi una fonte...'),
                          onSubmitted: (_) => _addSource(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(icon: const Icon(Icons.add), onPressed: _addSource),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('NOTE PERSONALI', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    onEditingComplete: _saveNote,
                    onTapOutside: (_) => _saveNote(),
                    decoration: const InputDecoration(hintText: 'Le tue note...'),
                  ),
                ],
              ),
      ),
    );
  }
}
