import 'package:supabase_flutter/supabase_flutter.dart';

class FocusService {
  final _client = Supabase.instance.client;

  Future<String> getFocusDelGiorno() async {
    final response = await _client.functions.invoke('focus-del-giorno');

    if (response.status != 200) {
      throw Exception('Edge Function error: ${response.data}');
    }

    return response.data['suggestion'] as String;
  }
}
