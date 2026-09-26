import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/verification/domain/picked_document.dart';
import 'package:app/features/verification/domain/provider_document.dart';

/// The documents a provider hands in, and what they are asked for.
///
/// Nothing here can verify anybody. Uploading puts a file in a private
/// bucket and asks the backend to record it; the backend checks the file
/// belongs to the caller, and the team alone decides the outcome.
///
/// Throws [AppFailure] on errors.
abstract interface class VerificationRepository {
  /// The document types this provider has to hand in, required ones first.
  Future<List<DocumentRequirement>> myRequirements();

  /// What they have handed in so far.
  Future<List<ProviderDocument>> myDocuments();

  /// Uploads [file] as proof of [type] and records it as waiting to be
  /// checked. Replaces an earlier document of the same type unless the
  /// team has already taken it in hand.
  Future<void> submit({
    required String providerId,
    required ProviderDocumentType type,
    required PickedDocument file,
  });
}

/// What the app accepts before it even tries to upload.
///
/// The limit is generous for a photo of a document and small enough that a
/// failed upload on mobile data does not cost the provider much.
const int maxDocumentBytes = 10 * 1024 * 1024;

const Set<String> allowedDocumentExtensions = {
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'heic',
  'webp',
};

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => SupabaseVerificationRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseVerificationRepository implements VerificationRepository {
  SupabaseVerificationRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'provider-documents';

  @override
  Future<List<DocumentRequirement>> myRequirements() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('my_required_documents');
      return [
        for (final row in rows)
          ?DocumentRequirement.fromJson(row as Map<String, dynamic>),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<ProviderDocument>> myDocuments() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('my_provider_documents');
      return [
        for (final row in rows)
          ?ProviderDocument.fromJson(row as Map<String, dynamic>),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> submit({
    required String providerId,
    required ProviderDocumentType type,
    required PickedDocument file,
  }) async {
    if (file.sizeInBytes > maxDocumentBytes) {
      throw AppFailure.documentTooLarge;
    }
    if (!allowedDocumentExtensions.contains(file.extension)) {
      throw AppFailure.documentTypeNotAllowed;
    }

    // The folder is the provider's own id. Storage refuses anything else,
    // and so does the function below -- the path is checked twice because
    // it is the one thing keeping two providers' documents apart.
    final path =
        '$providerId/${type.dbName}/'
        '${DateTime.now().microsecondsSinceEpoch}.${file.extension}';

    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            file.bytes,
            fileOptions: FileOptions(contentType: file.contentType),
          );
    } catch (error) {
      throw AppFailure.fromError(error);
    }

    List<dynamic> rows;
    try {
      rows = await _client.rpc<List<dynamic>>(
        'submit_provider_document',
        params: {
          'doc_type': type.dbName,
          'storage_path': path,
          'original_file_name': file.displayName,
        },
      );
    } catch (error) {
      // The row was refused, so the file has no business staying. Leaving
      // it would waste the provider's storage on something nothing points
      // at.
      await _removeQuietly(path);
      throw AppFailure.fromError(error);
    }

    final replaced = rows.singleOrNull as Map<String, dynamic>?;
    final oldPath = replaced?['replaced_path'] as String?;
    if (oldPath != null && oldPath != path) await _removeQuietly(oldPath);
  }

  /// Tidying up. A file that could not be removed is not worth failing an
  /// upload the provider already completed.
  Future<void> _removeQuietly(String path) async {
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // Nothing points at it any more; the team can clear it out later.
    }
  }
}
