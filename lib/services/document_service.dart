import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_document.dart';

class DocumentService {
  final _client = Supabase.instance.client;
  static const _bucket = 'user-documents';

  Future<List<UserDocument>> loadDocuments() async {
    final userId = _client.auth.currentUser!.id;

    final rows = await _client
        .from('user_documents')
        .select('id, label, storage_path, uploaded_at')
        .eq('user_id', userId)
        .order('uploaded_at', ascending: false);

    return rows
        .map((row) => UserDocument(
              id: row['id'] as String,
              label: row['label'] as String,
              storagePath: row['storage_path'] as String,
              uploadedAt: DateTime.parse(row['uploaded_at'] as String),
            ))
        .toList();
  }

  Future<void> uploadDocument({
    required File file,
    required String label,
    required String mimeType,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final fileName = file.path.split('/').last;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from(_bucket).upload(path, file);

    await _client.from('user_documents').insert({
      'user_id': userId,
      'storage_path': path,
      'label': label,
      'mime_type': mimeType,
    });
  }

  Future<void> deleteDocument(UserDocument document) async {
    await _client.storage.from(_bucket).remove([document.storagePath]);
    await _client.from('user_documents').delete().eq('id', document.id);
  }
}
