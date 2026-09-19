import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';

/// The signed-in user's own profile row.
///
/// The backend's security rules already restrict this to the caller's own
/// row, so no user id is passed in. Throws [AppFailure] on errors.
abstract interface class ProfileRepository {
  /// The chosen display name, or `null` while the account has none.
  Future<String?> myDisplayName();
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> myDisplayName() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      return row?['display_name'] as String?;
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
