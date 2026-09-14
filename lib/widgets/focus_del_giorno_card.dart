import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/focus_suggestion.dart';
import '../services/focus_service.dart';
import 'app_card.dart';

/// Self-contained AI card: the app's daily recap + suggestion, generated
/// from everything Pura tracks (routine, cycle, sleep, supplements,
/// fasting, plant diversity, personal notes, health context). Lives at
/// the top of Oggi rather than tucked away in Scopri — the AI's
/// understanding of the user is meant to be the app's actual center, not
/// one feature among many.
class FocusDelGiornoCard extends StatefulWidget {
  const FocusDelGiornoCard({super.key});

  @override
  State<FocusDelGiornoCard> createState() => _FocusDelGiornoCardState();
}

class _FocusDelGiornoCardState extends State<FocusDelGiornoCard> {
  final _focusService = FocusService();
  FocusSuggestion? _suggestion;
  BiologicalAgeEstimate? _biologicalAge;
  String? _error;
  bool _loading = false;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _focusService.getFocusDelGiorno();
      setState(() {
        _suggestion = result.suggestion;
        _biologicalAge = result.biologicalAge;
        _loading = false;
      });
    } on FocusRateLimitedException {
      setState(() {
        _error = AppStrings.of(context).limiteAiRaggiunto;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppStrings.of(context).impossibileGenerareConsiglio;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.14),
          theme.colorScheme.primary.withValues(alpha: 0.14),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.laTuaGiornata, style: theme.textTheme.labelMedium),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: TextStyle(color: theme.colorScheme.error))
          else if (_suggestion != null)
            _Suggestion(suggestion: _suggestion!)
          else
            Text(strings.ancoraNessunConsiglio),
          if (_biologicalAge != null) ...[
            const SizedBox(height: 12),
            _BiologicalAge(estimate: _biologicalAge!),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _generate,
            child: Text(strings.generaConsiglio),
          ),
        ],
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.suggestion});

  final FocusSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(suggestion.recap, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Text(
          suggestion.recommendation,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          suggestion.observation,
          style: TextStyle(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Chip(
              label: Text('${strings.affidabilita}: ${suggestion.confidence}'),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text('${strings.evidenza}: ${suggestion.evidenceStrength}'),
              visualDensity: VisualDensity.compact,
            ),
            if (suggestion.sources.isNotEmpty)
              Chip(
                label: Text('${strings.fonti}: ${suggestion.sources.join(", ")}'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

/// Deterministic PhenoAge estimate, never LLM-generated — see the edge
/// function for why. Always framed as informational/non-diagnostic, and
/// always states explicitly what's missing when it couldn't be computed.
class _BiologicalAge extends StatelessWidget {
  const _BiologicalAge({required this.estimate});

  final BiologicalAgeEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.etaBiologicaPhenoAge, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          if (estimate.computed)
            Text(
              strings.etaStimataAnni(
                estimate.phenotypicAgeYears!.toStringAsFixed(1),
                estimate.chronologicalAgeYears!.toStringAsFixed(1),
              ),
              style: theme.textTheme.bodyMedium,
            )
          else
            Text(
              estimate.reason ?? strings.stimaNonCalcolabile,
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 6),
          if (estimate.markersUsed.isNotEmpty)
            Text(
              strings.biomarcatoriUsati(estimate.markersUsed.join(", ")),
              style: theme.textTheme.bodySmall,
            ),
          if (estimate.markersMissing.isNotEmpty)
            Text(
              strings.mancanti(estimate.markersMissing.join(", ")),
              style: theme.textTheme.bodySmall,
            ),
          if (estimate.sourceDocument != null)
            Text(
              estimate.sourceDate != null
                  ? strings.fonteConData(estimate.sourceDocument!, estimate.sourceDate!)
                  : strings.fonteSenzaData(estimate.sourceDocument!),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
        ],
      ),
    );
  }
}
