import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/practice.dart';

class EvidenceBadge extends StatelessWidget {
  const EvidenceBadge({super.key, required this.level});

  final EvidenceLevel level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color color;
    switch (level) {
      case EvidenceLevel.alta:
        color = scheme.primary;
      case EvidenceLevel.moderata:
        color = scheme.secondary;
      case EvidenceLevel.limitata:
        color = scheme.outline;
      case EvidenceLevel.preliminare:
        color = scheme.outline.withValues(alpha: 0.7);
      case EvidenceLevel.nonVerificata:
        color = scheme.outline.withValues(alpha: 0.45);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        AppStrings.of(context).evidenzaLabel(evidenceLevelLabel(level, AppStrings.of(context))),
        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: color),
      ),
    );
  }
}
