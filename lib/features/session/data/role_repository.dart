import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/session/domain/app_role.dart';

/// Server-side roles of the signed-in user.
///
/// Throws [AppFailure] on errors.
abstract interface class RoleRepository {
  /// Adds [role] to the signed-in user. Safe to call if they already have it.
  /// The server only allows customer and provider.
  Future<void> addMyRole(AppRole role);
}

final roleRepositoryProvider = Provider<RoleRepository>(
  (ref) => SupabaseRoleRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseRoleRepository implements RoleRepository {
  SupabaseRoleRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> addMyRole(AppRole role) async {
    try {
      // Enum names match the database type public.app_role.
      await _client.rpc<void>(
        'add_my_role',
        params: {'requested_role': role.name},
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
