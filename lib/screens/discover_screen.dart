import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/focus_suggestion.dart';
import '../models/practice.dart' show EvidenceLevel;
import '../services/focus_service.dart';
import '../widgets/app_card.dart';
import '../widgets/evidence_badge.dart';
import '../widgets/page_header.dart';

const _curcuminSourceUrl = 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12257354/';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _focusService = FocusService();
  FocusSuggestion? _focusSuggestion;
  BiologicalAgeEstimate? _biologicalAge;
  String? _focusError;
  bool _focusLoading = false;

  Future<void> _generateFocus() async {
    setState(() {
      _focusLoading = true;
      _focusError = null;
    });

    try {
      final result = await _focusService.getFocusDelGiorno();
      setState(() {
        _focusSuggestion = result.suggestion;
        _biologicalAge = result.biologicalAge;
        _focusLoading = false;
      });
    } catch (e) {
      setState(() {
        _focusError = AppStrings.of(context).impossibileGenerareConsiglio;
        _focusLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const PageHeader(eyebrow: 'Questo mese', title: 'Scopri'),
          const SizedBox(height: 24),
          Text(AppStrings.of(context).focusDelGiorno.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 16),
          _buildFocusCard(),
          const SizedBox(height: 32),
          AppCard(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.35),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
              ],
            ),
            padding: const EdgeInsets.all(20),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INGREDIENTE DEL MESE', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                Text(
                  'Pepe nero × Curcumina',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  "Insieme alla curcumina, la piperina aumenta la biodisponibilità di circa "
                  "il 2000%. Lo stesso cucchiaino di curcuma diventa una molecola "
                  "significativamente diversa. Vanno sempre abbinati.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () =>
                      launchUrl(Uri.parse(_curcuminSourceUrl), mode: LaunchMode.externalApplication),
                  child: const EvidenceBadge(level: EvidenceLevel.moderata),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('SFIDE DA PROVARE', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 16),
          const _ChallengeCard(
            title: 'Sole negli occhi — 7 mattine',
            subtitle: '5 min al giorno',
            description:
                'Ancora il tuo orologio circadiano. All\'aperto, senza occhiali da sole, entro 30 minuti dal risveglio.',
            evidenceLevel: EvidenceLevel.moderata,
            evidenceNote: 'Fonte: vedi "Luce solare negli occhi" nel Ritual.',
          ),
          const _ChallengeCard(
            title: 'Inizio mouth taping',
            subtitle: '2 settimane',
            description:
                'Comincia con respirazione nasale di giorno. Poi brevi sessioni serali. Poi notti intere.',
            evidenceLevel: EvidenceLevel.nonVerificata,
          ),
          const _ChallengeCard(
            title: 'Finale freddo — 14 giorni',
            subtitle: '30 sec / doccia',
            description:
                'Termina ogni doccia con acqua fredda. Osserva come cambiano umore ed energia dal 7° giorno.',
            evidenceLevel: EvidenceLevel.moderata,
            evidenceNote: 'Fonte: vedi "Doccia fredda" nelle Pratiche.',
          ),
          const SizedBox(height: 32),
          Text('PROTOCOLLI STAGIONALI', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 16),
          const _ProtocolCard(
            title: 'Detox di primavera',
            description: 'Verdure amare, lavoro linfatico, serate più leggere.',
          ),
          const _ProtocolCard(
            title: 'Idratazione estiva',
            description: 'Sale marino al mattino, elettroliti, risciacqui freddi.',
          ),
          const _ProtocolCard(
            title: 'Immunità d\'autunno',
            description: 'Rotazione di funghi, controllo vitamina D, calore.',
          ),
          const _ProtocolCard(
            title: 'Calore d\'inverno',
            description: 'Golden milk, stack sauna, finestre di sonno più lunghe.',
          ),
        ],
      ),
    );
  }

  Widget _buildFocusCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.30),
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_focusLoading)
            const Center(child: CircularProgressIndicator())
          else if (_focusError != null)
            Text(
              _focusError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (_focusSuggestion != null)
            _buildFocusSuggestion(_focusSuggestion!)
          else
            Text(AppStrings.of(context).ancoraNessunConsiglio),
          if (_biologicalAge != null) ...[
            const SizedBox(height: 12),
            _buildBiologicalAge(_biologicalAge!),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _focusLoading ? null : _generateFocus,
            child: Text(AppStrings.of(context).generaConsiglio),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusSuggestion(FocusSuggestion suggestion) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          suggestion.recommendation,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          suggestion.observation,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
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

  /// Deterministic PhenoAge estimate, never LLM-generated — see the edge
  /// function for why. Always framed as informational/non-diagnostic, and
  /// always states explicitly what's missing when it couldn't be computed.
  Widget _buildBiologicalAge(BiologicalAgeEstimate estimate) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ETÀ BIOLOGICA (PHENOAGE)', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          if (estimate.computed)
            Text(
              '${estimate.phenotypicAgeYears!.toStringAsFixed(1)} anni stimati '
              '(età anagrafica ${estimate.chronologicalAgeYears!.toStringAsFixed(1)}) — '
              'informazione, non una diagnosi.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Text(
              estimate.reason ?? 'Stima non calcolabile.',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 6),
          if (estimate.markersUsed.isNotEmpty)
            Text(
              'Biomarcatori usati: ${estimate.markersUsed.join(", ")}.',
              style: theme.textTheme.bodySmall,
            ),
          if (estimate.markersMissing.isNotEmpty)
            Text(
              'Mancanti: ${estimate.markersMissing.join(", ")}.',
              style: theme.textTheme.bodySmall,
            ),
          if (estimate.sourceDocument != null)
            Text(
              'Fonte: ${estimate.sourceDocument}'
              '${estimate.sourceDate != null ? " (${estimate.sourceDate})" : ""}.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    this.evidenceLevel = EvidenceLevel.nonVerificata,
    this.evidenceNote,
  });

  final String title;
  final String subtitle;
  final String description;
  final EvidenceLevel evidenceLevel;
  final String? evidenceNote;

  @override
  Widget build(BuildContext context) {
    return AppCard(blur: 0, padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 10),
            EvidenceBadge(level: evidenceLevel),
            if (evidenceNote != null) ...[
              const SizedBox(height: 4),
              Text(evidenceNote!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppCard(blur: 0, padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 10),
            const EvidenceBadge(level: EvidenceLevel.nonVerificata),
          ],
        ),
      ),
    );
  }
}
