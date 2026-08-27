import '../l10n/app_strings.dart';
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

String practiceCategoryLabel(PracticeCategory category, AppStrings strings) {
  switch (category) {
    case PracticeCategory.sonnoRecupero:
      return strings.catSonnoRecupero;
    case PracticeCategory.respirazione:
      return strings.catRespirazione;
    case PracticeCategory.meditazioneStress:
      return strings.catMeditazioneStress;
    case PracticeCategory.movimento:
      return strings.catMovimento;
    case PracticeCategory.esposizioneLuce:
      return strings.catEsposizioneLuce;
    case PracticeCategory.alimentazione:
      return strings.catAlimentazione;
    case PracticeCategory.digiuno:
      return strings.catDigiuno;
    case PracticeCategory.recupero:
      return strings.catRecupero;
    case PracticeCategory.igieneOrale:
      return strings.catIgieneOrale;
    case PracticeCategory.pelleCapelli:
      return strings.catPelleCapelli;
    case PracticeCategory.monitoraggioBiomarcatori:
      return strings.catMonitoraggioBiomarcatori;
    case PracticeCategory.altro:
      return strings.catAltro;
  }
}

/// Never assign Alta/Moderata/Limitata/Preliminare without a real, checked
/// source behind it — nonVerificata ("da verificare") is the honest
/// default for anything not individually researched yet. It's a distinct
/// state from Preliminare: Preliminare means "checked, evidence is early-
/// stage"; nonVerificata means "not checked at all yet".
enum EvidenceLevel { alta, moderata, limitata, preliminare, nonVerificata }

String evidenceLevelLabel(EvidenceLevel level, AppStrings strings) {
  switch (level) {
    case EvidenceLevel.alta:
      return strings.evidenzaAlta;
    case EvidenceLevel.moderata:
      return strings.evidenzaModerata;
    case EvidenceLevel.limitata:
      return strings.evidenzaLimitata;
    case EvidenceLevel.preliminare:
      return strings.evidenzaPreliminare;
    case EvidenceLevel.nonVerificata:
      return strings.evidenzaDaVerificare;
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
