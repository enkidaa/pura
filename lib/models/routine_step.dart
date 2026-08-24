import 'catalog_source.dart';

class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.benefits,
    this.sources = const [],
  });

  final String id;
  final String title;
  final int durationMinutes;
  final String benefits;
  final List<CatalogSource> sources;
}

const morningRoutineSteps = [
  RoutineStep(
    id: 'sunlight',
    title: 'Luce solare negli occhi al mattino',
    durationMinutes: 15,
    benefits: 'All\'aperto, senza occhiali da sole, entro 30 minuti dal risveglio — il segnale più forte per sincronizzare il tuo orologio interno.',
    sources: [
      CatalogSource(
        title: 'Ocular light exposure interventions for sleep, circadian rhythms — Cochrane review (PMC)',
        url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC12427608/',
        note: 'Una delle pratiche con evidenza più solida della lista.',
      ),
    ],
  ),
  RoutineStep(
    id: 'lymphatic_drainage',
    title: 'Drenaggio linfatico del viso',
    durationMinutes: 5,
    benefits: 'Massaggio per sgonfiore e circolazione del viso.',
    sources: [
      CatalogSource(
        title: 'Lymphatic Drainage Massage — Cleveland Clinic',
        url: 'https://my.clevelandclinic.org/health/treatments/21768-lymphatic-drainage-massage',
        note: 'Validato clinicamente per il linfedema; per lo sgonfiore estetico le prove sono deboli e solo a breve termine.',
      ),
    ],
  ),
  RoutineStep(
    id: 'salt_water',
    title: 'Acqua e sale marino al mattino',
    durationMinutes: 3,
    benefits: 'Un bicchiere d\'acqua con un pizzico di sale marino al risveglio.',
    sources: [
      CatalogSource(
        title: 'Fact check: does morning salt water provide more hydration? (The Week)',
        url: 'https://www.theweek.in/news/health/2026/07/06/fact-check-does-morning-salt-water-provide-more-hydration-to-your-body.html',
        note: 'Nessuna prova di un beneficio reale rispetto all\'acqua semplice per una persona sana — pratica debole, tienila per gusto personale non per salute.',
      ),
    ],
  ),
  RoutineStep(
    id: 'cold_rinse',
    title: 'Risciacquo con acqua fredda',
    durationMinutes: 1,
    benefits: 'Chiudi con acqua fredda sul viso — attiva circolazione e sistema nervoso parasimpatico.',
    sources: [
      CatalogSource(
        title: 'Face cooling increases cerebral blood flow (NIH/PMC)',
        url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3429079/',
        note: 'Effetti fisiologici reali ma di breve durata — non c\'è prova di un beneficio duraturo per la pelle.',
      ),
    ],
  ),
];

// double_cleansing was originally listed under morning steps, but the
// Lovable prototype's real data has it as "ogni sera" — moved here to
// match, along with two more evening-specific steps from the same source.
const eveningRoutineSteps = [
  RoutineStep(
    id: 'double_cleansing',
    title: 'Doppia detersione',
    durationMinutes: 4,
    benefits: 'Detergente oleoso seguito da uno a base d\'acqua — rimuove SPF, trucco e inquinamento in profondità.',
    sources: [
      CatalogSource(
        title: 'Double Cleansing Method Explained — Cleveland Clinic',
        url: 'https://health.clevelandclinic.org/double-cleansing-explained',
        note: 'Pratica ragionevole, non indispensabile per tutti — rischio di over-detersione su pelli secche/sensibili.',
      ),
    ],
  ),
  RoutineStep(
    id: 'targeted_serum',
    title: 'Siero mirato',
    durationMinutes: 1,
    benefits: 'Siero alla vitamina C — antiossidante, sostiene la sintesi di collagene.',
    sources: [
      CatalogSource(
        title: 'Efficacy of topical vitamin C in melasma and photoaging: systematic review (PubMed)',
        url: 'https://pubmed.ncbi.nlm.nih.gov/37128827/',
        note: 'Evidenza solida — RCT mostrano riduzione delle rughe e sintesi di collagene confermata da biopsia.',
      ),
    ],
  ),
  RoutineStep(
    id: 'retinoid',
    title: 'Retinoide (gradualmente)',
    durationMinutes: 1,
    benefits: 'Introduzione graduale — "partire piano" è il protocollo clinico reale per ridurre l\'irritazione.',
    sources: [
      CatalogSource(
        title: 'An Updated Review of Topical Tretinoin in Dermatology (NIH/PMC)',
        url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12653878/',
        note: 'Gold standard in dermatologia, sostenuto dall\'American Academy of Dermatology.',
      ),
    ],
  ),
];
