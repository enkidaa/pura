import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_document.dart';

/// Thrown by [DocumentService.uploadDocument] when the file fails
/// client-side validation — [message] is meant to be shown to the user
/// directly, not just logged.
class DocumentValidationException implements Exception {
  const DocumentValidationException(this.message);
  final String message;
}

// Mirrors the user-documents bucket's own file_size_limit/allowed_mime_types
// (see supabase/migrations/0028_storage_limits.sql) — checking here first
// gives a clear message instead of a raw storage-API rejection.
const _maxDocumentBytes = 10 * 1024 * 1024;
const _allowedDocumentMimeTypes = ['application/pdf', 'image/jpeg', 'image/png'];

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
    if (!_allowedDocumentMimeTypes.contains(mimeType)) {
      throw const DocumentValidationException(
        'Formato non supportato — solo PDF, JPG o PNG.',
      );
    }
    final sizeBytes = await file.length();
    if (sizeBytes > _maxDocumentBytes) {
      final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      throw DocumentValidationException(
        'File troppo grande ($sizeMb MB) — il limite è 10 MB.',
      );
    }

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
