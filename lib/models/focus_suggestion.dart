class FocusSuggestion {
  const FocusSuggestion({
    required this.observation,
    required this.evidence,
    required this.recommendation,
    required this.confidence,
    required this.evidenceStrength,
    required this.sources,
    required this.safetyCategory,
  });

  factory FocusSuggestion.fromJson(Map<String, dynamic> json) {
    return FocusSuggestion(
      observation: json['observation'] as String,
      evidence: List<String>.from(json['evidence'] as List),
      recommendation: json['recommendation'] as String,
      confidence: json['confidence'] as String,
      evidenceStrength: json['evidence_strength'] as String,
      sources: List<String>.from(json['sources'] as List),
      safetyCategory: json['safety_category'] as String,
    );
  }

  final String observation;
  final List<String> evidence;
  final String recommendation;
  final String confidence;
  final String evidenceStrength;
  final List<String> sources;
  final String safetyCategory;
}

/// A PhenoAge biological-age estimate computed deterministically (not by
/// the LLM) from biomarkers extracted out of the user's most recently
/// uploaded document, when it's a blood panel with all 9 required markers
/// and a birth date is set in Profilo. Never a diagnosis — always
/// presented as informational, always cites which document/date it came
/// from, and always states plainly what's missing when it can't compute.
class BiologicalAgeEstimate {
  const BiologicalAgeEstimate({
    required this.computed,
    this.phenotypicAgeYears,
    this.chronologicalAgeYears,
    this.markersUsed = const [],
    this.markersMissing = const [],
    this.sourceDocument,
    this.sourceDate,
    this.reason,
  });

  factory BiologicalAgeEstimate.fromJson(Map<String, dynamic> json) {
    return BiologicalAgeEstimate(
      computed: json['computed'] as bool,
      phenotypicAgeYears: (json['phenotypic_age_years'] as num?)?.toDouble(),
      chronologicalAgeYears: (json['chronological_age_years'] as num?)?.toDouble(),
      markersUsed: List<String>.from(json['markers_used'] as List? ?? const []),
      markersMissing: List<String>.from(json['markers_missing'] as List? ?? const []),
      sourceDocument: json['source_document'] as String?,
      sourceDate: json['source_date'] as String?,
      reason: json['reason'] as String?,
    );
  }

  final bool computed;
  final double? phenotypicAgeYears;
  final double? chronologicalAgeYears;
  final List<String> markersUsed;
  final List<String> markersMissing;
  final String? sourceDocument;
  final String? sourceDate;
  final String? reason;
}
