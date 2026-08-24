import 'app_settings.dart';
import 'catalog_source.dart';
import 'practice.dart' show EvidenceLevel;

class SupplementCatalogItem {
  const SupplementCatalogItem({
    required this.id,
    required this.name,
    required this.frequency,
    required this.durationMinutes,
    required this.benefits,
    required this.evidenceLevel,
    this.timeOfDay,
    this.sources = const [],
    this.approachAffinity = const [],
  });

  final String id;
  final String name;
  final String frequency;
  final int durationMinutes;
  final String benefits;
  final String? timeOfDay;
  final EvidenceLevel evidenceLevel;

  /// Real, checked sources — never auto-generated. See CatalogSource.note
  /// for where the evidence is preliminary rather than settled.
  final List<CatalogSource> sources;

  /// Which saved WellnessApproach(es) this item best fits, purely as a
  /// categorization of its own real evidence character (e.g. strong-RCT
  /// items lean "scientific", traditional/botanical items lean "natural") —
  /// used only to order "Consigliati per te", never to invent new claims.
  final List<WellnessApproach> approachAffinity;
}

/// Copied from the Lovable prototype's Pratiche > Integratori group — the
/// catalog is fixed (matches what's actually there), not user-editable.
const supplementCatalog = [
  SupplementCatalogItem(
    id: 'sup-nad',
    name: 'Stack di supporto NAD+',
    frequency: 'Quotidiano',
    durationMinutes: 1,
    timeOfDay: 'Mattino',
    benefits: 'Precursori (NMN / NR) per sostenere le vie energetiche cellulari.',
    evidenceLevel: EvidenceLevel.preliminare,
    approachAffinity: [WellnessApproach.scientific],
    sources: [
      CatalogSource(
        title: 'Improved Physical Performance Parameters in Patients Taking NMN: Systematic Review of RCTs (NIH/PMC)',
        url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11365583/',
        note: 'Evidenza reale ma preliminare: alza i livelli di NAD+ nel sangue, i benefici funzionali umani sono ancora incostanti.',
      ),
    ],
  ),
  SupplementCatalogItem(
    id: 'sup-creatine',
    name: 'Creatina monoidrato',
    frequency: 'Quotidiano',
    durationMinutes: 1,
    benefits: '3–5 g/die — forza, recupero, supporto cognitivo.',
    evidenceLevel: EvidenceLevel.moderata,
    approachAffinity: [WellnessApproach.scientific],
    sources: [
      CatalogSource(
        title: 'Creatine supplementation and cognitive function: systematic review and meta-analysis (NIH/PMC, 2024)',
        url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11275561/',
        note: 'Forza/recupero: evidenza solida e consolidata. Supporto cognitivo: evidenza reale ma di certezza da bassa a moderata.',
      ),
    ],
  ),
  SupplementCatalogItem(
    id: 'sup-magnesium',
    name: 'Magnesio (glicinato/treonato)',
    frequency: 'Sera',
    durationMinutes: 1,
    timeOfDay: 'Sera',
    benefits: 'Sonno, sistema nervoso, rilassamento muscolare.',
    evidenceLevel: EvidenceLevel.moderata,
    approachAffinity: [WellnessApproach.natural, WellnessApproach.balanced],
    sources: [
      CatalogSource(
        title: 'Magnesium — Health Professional Fact Sheet (NIH Office of Dietary Supplements)',
        url: 'https://ods.od.nih.gov/factsheets/Magnesium-HealthProfessional/',
        note: 'Ben supportato per il magnesio in generale; studi specifici sulla forma glicinato sono ancora pochi.',
      ),
    ],
  ),
  SupplementCatalogItem(
    id: 'sup-omega3',
    name: 'Omega-3 (EPA/DHA)',
    frequency: 'Quotidiano',
    durationMinutes: 1,
    benefits: 'Antinfiammatorio, supporto cardiovascolare e cerebrale.',
    evidenceLevel: EvidenceLevel.alta,
    approachAffinity: [WellnessApproach.scientific, WellnessApproach.balanced],
    sources: [
      CatalogSource(
        title: 'Omega-3 Fatty Acids — Health Professional Fact Sheet (NIH Office of Dietary Supplements)',
        url: 'https://ods.od.nih.gov/factsheets/Omega3FattyAcids-HealthProfessional/',
        note: 'Il livello di evidenza più solido tra i sei — claim cardiovascolare riconosciuto anche dalla FDA.',
      ),
    ],
  ),
  SupplementCatalogItem(
    id: 'sup-curcumin',
    name: 'Curcumina antinfiammatoria',
    frequency: 'Quotidiano',
    durationMinutes: 1,
    benefits: 'Con piperina + grassi per la biodisponibilità.',
    evidenceLevel: EvidenceLevel.moderata,
    approachAffinity: [WellnessApproach.natural],
    sources: [
      CatalogSource(
        title: 'Effects of Curcuminoids Plus Piperine on Inflammation: GRADE Systematic Review and Meta-Analysis (NIH/PMC)',
        url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12257354/',
      ),
    ],
  ),
  SupplementCatalogItem(
    id: 'sup-antiox',
    name: 'Stack antiossidante',
    frequency: 'Quotidiano',
    durationMinutes: 1,
    benefits: 'Vitamina C, E, selenio, precursori del glutatione se necessari.',
    evidenceLevel: EvidenceLevel.limitata,
    approachAffinity: [WellnessApproach.natural],
    sources: [
      CatalogSource(
        title: 'Antioxidant Supplements: What You Need To Know (NCCIH — NIH)',
        url: 'https://www.nccih.nih.gov/health/antioxidant-supplements-what-you-need-to-know',
        note: 'Il ruolo antiossidante è reale a livello meccanicistico; l\'NCCIH segnala che le prove di beneficio clinico da integrazione (vs. dieta) restano limitate.',
      ),
    ],
  ),
];
