import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/core/media/picked_media.dart';
import 'package:app/features/requests/domain/request_photo.dart';

/// The photos on a request.
///
/// Nothing here decides who may look. The bucket is private and the backend
/// answers that question twice — once for the list, once for each file — so
/// a screen asking for photos it has no right to simply gets none back.
///
/// Throws [AppFailure] on errors.
abstract interface class RequestPhotoRepository {
  /// The photos on [requestId], each with a link that expires.
  ///
  /// Empty for somebody with no business seeing them, rather than an error:
  /// there is nothing for them to be told about.
  Future<List<RequestPhoto>> photosOf(String requestId);

  /// Uploads [photo] and records it against the caller's own request.
  Future<void> attach({required String requestId, required PickedMedia photo});

  /// Takes one photo back off, file and all.
  Future<void> remove(String photoId);
}

/// What the app checks before it uploads anything, matching the limits on
/// the bucket itself. Caught here so a phone on mobile data does not spend
/// the upload to be told the same thing.
const int maxRequestPhotoBytes = 10 * 1024 * 1024;

const Set<String> allowedRequestPhotoExtensions = {
  'jpg',
  'jpeg',
  'png',
  'heic',
  'webp',
};

/// The most photos one request may carry. The backend holds the same
/// number; this one only spares the customer a pointless upload.
const int maxRequestPhotos = 6;

/// How long a link to a photo stays good for.
///
/// Long enough to scroll a list and open one, short enough that a link
/// copied out of the app is worthless by the time anybody tries it.
const Duration _linkLifetime = Duration(minutes: 30);

final requestPhotoRepositoryProvider = Provider<RequestPhotoRepository>(
  (ref) => SupabaseRequestPhotoRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseRequestPhotoRepository implements RequestPhotoRepository {
  SupabaseRequestPhotoRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'request-photos';

  @override
  Future<List<RequestPhoto>> photosOf(String requestId) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'photos_for_request',
        params: {'target_request_id': requestId},
      );
      if (rows.isEmpty) return const [];

      final paths = <String, String>{
        for (final row in rows.cast<Map<String, dynamic>>())
          row['storage_path'] as String: row['id'] as String,
      };

      // One round trip for all of them, in the order the backend gave.
      final signed = await _client.storage
          .from(_bucket)
          .createSignedUrlsResult(paths.keys.toList(), _linkLifetime.inSeconds);

      // Anything storage could not sign is simply left out below. A row
      // whose file has gone missing shows as one photo fewer, which is the
      // truth, rather than a broken frame in the middle of a row.
      final urls = <String, String>{
        for (final one in signed)
          if (one is SignedUrlSuccess) one.path: one.signedUrl,
      };

      return [
        for (final entry in paths.entries)
          if (urls[entry.key] case final url?)
            RequestPhoto(id: entry.value, url: url),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> attach({
    required String requestId,
    required PickedMedia photo,
  }) async {
    if (photo.sizeInBytes > maxRequestPhotoBytes) {
      throw AppFailure.documentTooLarge;
    }
    if (!allowedRequestPhotoExtensions.contains(photo.extension)) {
      throw AppFailure.documentTypeNotAllowed;
    }

    // The folder is the request's own id. Storage refuses anything else,
    // and so does the function below — the path is checked twice because
    // it is what keeps one customer's photos out of another's request.
    final path =
        '$requestId/${DateTime.now().microsecondsSinceEpoch}.${photo.extension}';

    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            photo.bytes,
            fileOptions: FileOptions(contentType: photo.contentType),
          );
    } catch (error) {
      throw AppFailure.fromError(error);
    }

    try {
      await _client.rpc<Object?>(
        'add_request_photo',
        params: {'target_request_id': requestId, 'storage_path': path},
      );
    } catch (error) {
      // The row was refused, so the file has no business staying. Nothing
      // points at it, and a photo of somebody's flat sitting in a bucket
      // that nothing references is the worst of both worlds.
      await _removeQuietly(path);
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> remove(String photoId) async {
    String path;
    try {
      path = await _client.rpc<String>(
        'remove_request_photo',
        params: {'photo_id': photoId},
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }

    // The row went first on purpose: from here on nothing points at the
    // file, so a failed delete leaves a stray file rather than a photo the
    // customer thinks they took back.
    await _removeQuietly(path);
  }

  Future<void> _removeQuietly(String path) async {
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // Nothing points at it any more; it can be cleared out later.
    }
  }
}
