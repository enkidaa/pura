import 'app_settings.dart';
import 'catalog_source.dart';

enum PracticeCategory {
  sonnoRecupero,
  respirazione,
  meditazioneStress,
  movimento,
  esposizioneLuce,
  alimentazione,
  digiuno,
  recupero,
  igieneOrale,
  pelleCapelli,
  monitoraggioBiomarcatori,
  altro,
}

String practiceCategoryLabel(PracticeCategory category) {
  switch (category) {
    case PracticeCategory.sonnoRecupero:
      return 'Sonno e recupero';
    case PracticeCategory.respirazione:
      return 'Respirazione';
    case PracticeCategory.meditazioneStress:
      return 'Meditazione e stress';
    case PracticeCategory.movimento:
      return 'Movimento';
    case PracticeCategory.esposizioneLuce:
      return 'Esposizione alla luce';
    case PracticeCategory.alimentazione:
      return 'Alimentazione';
    case PracticeCategory.digiuno:
      return 'Digiuno';
    case PracticeCategory.recupero:
      return 'Recupero';
    case PracticeCategory.igieneOrale:
      return 'Igiene orale';
    case PracticeCategory.pelleCapelli:
      return 'Pelle e capelli';
    case PracticeCategory.monitoraggioBiomarcatori:
      return 'Monitoraggio e biomarcatori';
    case PracticeCategory.altro:
      return 'Altre pratiche';
  }
}

/// Never assign Alta/Moderata/Limitata/Preliminare without a real, checked
/// source behind it — nonVerificata ("da verificare") is the honest
/// default for anything not individually researched yet. It's a distinct
/// state from Preliminare: Preliminare means "checked, evidence is early-
/// stage"; nonVerificata means "not checked at all yet".
enum EvidenceLevel { alta, moderata, limitata, preliminare, nonVerificata }

String evidenceLevelLabel(EvidenceLevel level) {
  switch (level) {
    case EvidenceLevel.alta:
      return 'Alta';
    case EvidenceLevel.moderata:
      return 'Moderata';
    case EvidenceLevel.limitata:
      return 'Limitata';
    case EvidenceLevel.preliminare:
      return 'Preliminare';
    case EvidenceLevel.nonVerificata:
      return 'Da verificare';
  }
}

class Practice {
  const Practice({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.goal,
    required this.benefits,
    required this.howToStart,
    required this.frequency,
    required this.evidenceLevel,
    this.sources = const [],
    this.risks,
    this.tags = const [],
    this.approachAffinity = const [],
    this.linksToFastingDetail = false,
  });

  /// True when [approach] is one of this practice's [approachAffinity] tags
  /// — used to weight ordering/highlighting toward the user's saved
  /// preference, never to hide or block practices outright.
  bool matchesApproach(WellnessApproach approach) => approachAffinity.contains(approach);

  final String id;
  final String name;
  final PracticeCategory category;
  final String description;
  final String goal;
  final String benefits;
  final String howToStart;
  final String frequency;
  final EvidenceLevel evidenceLevel;
  final List<CatalogSource> sources;

  /// Risks, contraindications, or who should be cautious — null when there's
  /// nothing notable to flag.
  final String? risks;

  /// Free-form hints (e.g. 'sonno', 'energia', 'stress') for future
  /// personalized ranking — not used by any logic yet.
  final List<String> tags;

  /// Which WellnessApproach preference(s) this practice best fits — also
  /// just modeled for future ranking, not applied anywhere yet.
  final List<WellnessApproach> approachAffinity;

  /// True only for the intermittent-fasting entry: its detail page is the
  /// existing FastingDetailScreen (meal tracking), not the generic one.
  final bool linksToFastingDetail;
}
