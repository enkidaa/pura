import 'package:flutter/material.dart';

import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const PageHeader(eyebrow: 'Questo mese', title: 'Scopri'),
          const SizedBox(height: 24),
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
          ),
          const _ChallengeCard(
            title: 'Inizio mouth taping',
            subtitle: '2 settimane',
            description:
                'Comincia con respirazione nasale di giorno. Poi brevi sessioni serali. Poi notti intere.',
          ),
          const _ChallengeCard(
            title: 'Finale freddo — 14 giorni',
            subtitle: '30 sec / doccia',
            description:
                'Termina ogni doccia con acqua fredda. Osserva come cambiano umore ed energia dal 7° giorno.',
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
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppCard(padding: EdgeInsets.zero, 
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Text(description),
          ],
        ),
        isThreeLine: true,
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
    return AppCard(padding: EdgeInsets.zero, 
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
