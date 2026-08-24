import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/focus_suggestion.dart';

class FocusResult {
  const FocusResult({required this.suggestion, this.biologicalAge});
  final FocusSuggestion suggestion;
  final BiologicalAgeEstimate? biologicalAge;
}

class FocusService {
  final _client = Supabase.instance.client;

  Future<FocusResult> getFocusDelGiorno() async {
    final response = await _client.functions.invoke('focus-del-giorno');

    if (response.status != 200) {
      throw Exception('Edge Function error: ${response.data}');
    }

    final bioAgeJson = response.data['biological_age'] as Map<String, dynamic>?;

    return FocusResult(
      suggestion: FocusSuggestion.fromJson(response.data['suggestion'] as Map<String, dynamic>),
      biologicalAge: bioAgeJson == null ? null : BiologicalAgeEstimate.fromJson(bioAgeJson),
    );
  }
}
