import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/core/media/picked_media.dart';
import 'package:app/features/profile/domain/user_profile.dart';

/// The signed-in user's own profile row.
///
/// The backend's security rules already restrict this to the caller's own
/// row, so no user id is passed in. Throws [AppFailure] on errors.
abstract interface class ProfileRepository {
  /// The chosen display name, or `null` while the account has none.
  Future<String?> myDisplayName();

  /// Name and picture together, for the screen that edits them.
  Future<UserProfile> myProfile();

  /// Writes the name. Trimmed, and an empty name clears it rather than
  /// storing a row full of spaces.
  Future<void> saveDisplayName(String? name);

  /// Uploads [picture] and records it as this account's avatar.
  ///
  /// Returns the address it ended up at. The previous picture is removed
  /// afterwards, so a person changing their photo ten times does not leave
  /// ten photos behind.
  Future<String> saveAvatar(PickedMedia picture);

  /// Removes the picture and the file behind it.
  Future<void> removeAvatar();
}

/// What the app accepts before it uploads anything, matching the limits on
/// the bucket itself.
const int maxAvatarBytes = 2 * 1024 * 1024;

const Set<String> allowedAvatarExtensions = {
  'jpg',
  'jpeg',
  'png',
  'heic',
  'webp',
};

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'avatars';

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<String?> myDisplayName() async => (await myProfile()).displayName;

  @override
  Future<UserProfile> myProfile() async {
    final userId = _userId;
    if (userId == null) return const UserProfile();
    try {
      final row = await _client
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return row == null ? const UserProfile() : UserProfile.fromJson(row);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> saveDisplayName(String? name) async {
    final userId = _userId;
    if (userId == null) throw AppFailure.unknown;
    final trimmed = (name ?? '').trim();
    try {
      await _client
          .from('profiles')
          .update({'display_name': trimmed.isEmpty ? null : trimmed})
          .eq('id', userId);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<String> saveAvatar(PickedMedia picture) async {
    final userId = _userId;
    if (userId == null) throw AppFailure.unknown;

    if (picture.sizeInBytes > maxAvatarBytes) throw AppFailure.documentTooLarge;
    if (!allowedAvatarExtensions.contains(picture.extension)) {
      throw AppFailure.documentTypeNotAllowed;
    }

    final previous = (await myProfile()).avatarUrl;
    // The folder is the account's own id, which is what storage checks.
    final path =
        '$userId/${DateTime.now().microsecondsSinceEpoch}.${picture.extension}';

    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            picture.bytes,
            fileOptions: FileOptions(contentType: picture.contentType),
          );
      final url = _client.storage.from(_bucket).getPublicUrl(path);
      await _client
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', userId);
      await _removeQuietly(previous);
      return url;
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> removeAvatar() async {
    final userId = _userId;
    if (userId == null) throw AppFailure.unknown;
    final previous = (await myProfile()).avatarUrl;
    try {
      await _client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', userId);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
    await _removeQuietly(previous);
  }

  /// Deletes the file an address points at. Best effort: a leftover file
  /// nothing refers to is not worth failing a save the person completed.
  Future<void> _removeQuietly(String? url) async {
    if (url == null || url.isEmpty) return;
    const marker = '/avatars/';
    final at = url.indexOf(marker);
    if (at < 0) return;
    final path = url.substring(at + marker.length);
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // Nothing points at it any more.
    }
  }
}
