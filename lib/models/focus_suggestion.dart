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
