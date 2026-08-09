import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/focus_suggestion.dart';

class FocusService {
  final _client = Supabase.instance.client;

  Future<FocusSuggestion> getFocusDelGiorno() async {
    final response = await _client.functions.invoke('focus-del-giorno');

    if (response.status != 200) {
      throw Exception('Edge Function error: ${response.data}');
    }

    return FocusSuggestion.fromJson(
      response.data['suggestion'] as Map<String, dynamic>,
    );
  }
}
