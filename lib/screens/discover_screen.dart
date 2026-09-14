import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/practice.dart' show EvidenceLevel;
import '../widgets/app_card.dart';
import '../widgets/evidence_badge.dart';
import '../widgets/page_header.dart';

const _curcuminSourceUrl = 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12257354/';

/// Seasonal/editorial content only — the AI recap+suggestion lives on Oggi
/// now (FocusDelGiornoCard), not here, so this stays a plain stateless
/// browse screen.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

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
          AppCard(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.16),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.16),
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
