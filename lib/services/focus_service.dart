import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/focus_suggestion.dart';

class FocusResult {
  const FocusResult({required this.suggestion, this.biologicalAge});
  final FocusSuggestion suggestion;
  final BiologicalAgeEstimate? biologicalAge;
}

/// Thrown specifically for a 429 from the edge function — Gemini's free
/// tier caps at 5 requests/minute, and one generation already costs 2-3
/// calls (suggestion + safety classifier + optional biomarker
/// extraction), so this is a real, expected "wait a moment" condition,
/// not a generic failure. Kept distinct so the UI can say that plainly
/// instead of a one-size-fits-all error message.
class FocusRateLimitedException implements Exception {
  const FocusRateLimitedException();
}

class FocusService {
  final _client = Supabase.instance.client;

  Future<FocusResult> getFocusDelGiorno() async {
    try {
      final response = await _client.functions.invoke('focus-del-giorno');

      final bioAgeJson = response.data['biological_age'] as Map<String, dynamic>?;

      return FocusResult(
        suggestion: FocusSuggestion.fromJson(response.data['suggestion'] as Map<String, dynamic>),
        biologicalAge: bioAgeJson == null ? null : BiologicalAgeEstimate.fromJson(bioAgeJson),
      );
    } on FunctionException catch (e) {
      if (e.status == 429) throw const FocusRateLimitedException();
      rethrow;
    }
  }
}
