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
    final strings = AppStrings.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          PageHeader(eyebrow: strings.questoMese, title: strings.scopri),
          const SizedBox(height: 24),
          Text(strings.focusDelGiorno.toUpperCase(),
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
                Text(strings.ingredienteDelMese, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                Text(
                  strings.pepeNeroCurcumina,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  strings.pepeNeroSpiegazione,
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
          Text(strings.sfideDaProvare, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 16),
          _ChallengeCard(
            title: strings.soleNegliOcchiTitolo,
            subtitle: strings.soleNegliOcchiSottotitolo,
            description: strings.soleNegliOcchiDescrizione,
            evidenceLevel: EvidenceLevel.moderata,
            evidenceNote: strings.soleNegliOcchiFonte,
          ),
          _ChallengeCard(
            title: strings.mouthTapingTitolo,
            subtitle: strings.mouthTapingSottotitolo,
            description: strings.mouthTapingDescrizione,
            evidenceLevel: EvidenceLevel.nonVerificata,
          ),
          _ChallengeCard(
            title: strings.finaleFreddoTitolo,
            subtitle: strings.finaleFreddoSottotitolo,
            description: strings.finaleFreddoDescrizione,
            evidenceLevel: EvidenceLevel.moderata,
            evidenceNote: strings.finaleFreddoFonte,
          ),
          const SizedBox(height: 32),
          Text(strings.protocolliStagionali, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 16),
          _ProtocolCard(
            title: strings.detoxPrimaveraTitolo,
            description: strings.detoxPrimaveraDescrizione,
          ),
          _ProtocolCard(
            title: strings.idratazioneEstivaTitolo,
            description: strings.idratazioneEstivaDescrizione,
          ),
          _ProtocolCard(
            title: strings.immunitaAutunnoTitolo,
            description: strings.immunitaAutunnoDescrizione,
          ),
          _ProtocolCard(
            title: strings.caloreInvernoTitolo,
            description: strings.caloreInvernoDescrizione,
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
