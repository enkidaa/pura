import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

enum SkincarePeriod { mattino, sera }

class SkincarePhotoService {
  final _client = Supabase.instance.client;
  static const _bucket = 'skincare-photos';

  Future<Map<SkincarePeriod, String>> loadTodaySignedUrls() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('skincare_photos')
        .select('period, storage_path')
        .eq('user_id', userId)
        .eq('log_date', _todayString());

    final result = <SkincarePeriod, String>{};
    for (final row in rows) {
      final period = SkincarePeriod.values.byName(row['period'] as String);
      final signedUrl = await _client.storage
          .from(_bucket)
          .createSignedUrl(row['storage_path'] as String, 3600);
      result[period] = signedUrl;
    }
    return result;
  }

  Future<void> uploadPhoto(SkincarePeriod period, File file) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/${_todayString()}_${period.name}.jpg';

    await _client.storage
        .from(_bucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    await _client.from('skincare_photos').upsert(
      {
        'user_id': userId,
        'log_date': _todayString(),
        'period': period.name,
        'storage_path': path,
      },
      onConflict: 'user_id,log_date,period',
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
